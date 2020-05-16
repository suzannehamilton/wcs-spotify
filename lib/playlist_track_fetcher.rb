class PlaylistTrackFetcher
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def fetch_tracks(output_path)
    search_terms = [
      # "wcs",
      "westcoastswing",
      # "west coastswing",
      # "westcoast swing",
      # "west coast swing",
      # "westie",
    ]

    # TODO: Reference file relative to this one?
    config = YAML::load_file("config.yaml")

    RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

    wcs_playlists = search_terms.map { |term|
      @playlist_search.search_playlists(term)
    }.flatten

    logger.info "Found #{wcs_playlists.length} playlists"

    CSV.open(output_path, "wb") do |csv|
      csv << [
        "track_id",
        "added_at",
        "full_name",
        "artist_ids",
        "artist_names",
        "release_date",
        "release_date_precision",
        "available_markets",
      ]

      wcs_playlists.each do |playlist|
        logger.info playlist.name

        total_tracks = playlist.total
        track_sets = (total_tracks / 100.to_f).ceil

        track_sets.times do |track_offset|
          track_set = get_playlist_tracks(playlist, track_offset * 100)
          tracks_added_at = get_playlist_added_dates(playlist)

          track_set.each do |track|
            added_at = tracks_added_at[track.id]

            artist_ids = track.artists.map { |artist| artist.id }.join(",")
            artist_names = track.artists.map { |artist| artist.name }.join(",")

            release_date = track.album.release_date
            release_date_precision = track.album.release_date_precision
            markets = track.album.available_markets.join(",")

            csv << [
              track.id,
              added_at,
              track.name,
              artist_ids,
              artist_names,
              release_date,
              release_date_precision,
              markets,
            ]
          end
        end
      end
    end
  end

private

  attr_reader :logger

  def get_playlist_tracks(playlist, offset)
    Retriable.retriable on: RestClient::RequestTimeout, tries: 3 do
      begin
        playlist.tracks(offset: offset)
      rescue RestClient::ResourceNotFound
        logger.warn "Could not find track for playlist '#{playlist.uri}' with offset #{offset}"
        []
      rescue URI::InvalidURIError
        logger.warn "Playlist '#{playlist.uri}' has invalid URI"
        []
      rescue NoMethodError => e
        logger.warn "Playlist '#{playlist.uri}' has track total #{playlist.total} and error '#{e}'"
        []
      end
    end
  end

  def get_playlist_added_dates(playlist)
    Retriable.retriable on: RestClient::RequestTimeout, tries: 3 do
      begin
        return playlist.tracks_added_at
      rescue RestClient::ResourceNotFound
        logger.warn "Could not find track-added dates for playlist '#{playlist.uri}'"
        []
      rescue URI::InvalidURIError
        logger.warn "Playlist '#{playlist.uri}' has invalid URI"
        []
      rescue NoMethodError => e
        logger.warn "Playlist '#{playlist.uri}' has track total #{playlist.total} and error '#{e}'"
        []
      end
    end
  end
end
