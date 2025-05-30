require_relative "spotify/spotify_retry"

class SourceTrackFetcher
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def fetch_tracks(playlists_path, output_path)
    playlists = CSV.read(playlists_path, headers: true)
    logger.info "Found #{playlists.length} playlists"

    progress_file_path = output_path + ".progress"
    in_progress_playlist, in_progress_offset = if File.exist?(progress_file_path)
      playlist, offset = CSV.read(progress_file_path).last
      [playlist, offset.to_i]
    else
      [playlists[0]["id"], 0]
    end
    in_progress_playlist_index = playlists.find_index { |p| p["id"] == in_progress_playlist }
    playlists = playlists.drop(in_progress_playlist_index)

    logger.info "Starting from playlist #{in_progress_playlist} at index #{in_progress_playlist_index} with offset #{in_progress_offset}"

    # TODO: Reference file relative to this one?
    config = YAML::load_file("config.yaml")

    RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

    ignored_playlists = Set.new(config["ignored_playlists"])

    CSV.open(output_path, "ab") do |csv|
      csv << [
        "track_id",
        "added_at",
        "full_name",
        "artist_ids",
        "artist_names",
        "release_date",
        "release_date_precision",
        "available_markets",
      ] unless File.exist?(progress_file_path)

      CSV.open(progress_file_path, "ab") do |progress_file|
        playlists.each do |playlist_summary|
          playlist_id = playlist_summary["id"]
          next if ignored_playlists.include?(playlist_id)

          playlist = get_playlist(playlist_id)
          next if playlist.nil?
          logger.info "#{playlist_id}: '#{playlist.name}', #{playlist.total} tracks"

          total_tracks = playlist.total
          track_sets = (total_tracks / 100.to_f).ceil

          offset_start = playlist_id == in_progress_playlist ? in_progress_offset : 0
          (offset_start...track_sets).each do |track_offset|
            progress_file << [playlist_id, track_offset]

            track_set = get_playlist_tracks(playlist, track_offset * 100)
            tracks_added_at = get_playlist_added_dates(playlist)

            track_set.each do |track|
              if (!track.id.nil? && track.type == "track")
                csv << extract_track(track, tracks_added_at)
              end
            end
          end
        end
      end
    end
  end

private

  attr_reader :logger

  def get_playlist_tracks(playlist, offset)
    SpotifyRetry::retry do
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
    SpotifyRetry::retry do
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

  def get_playlist(playlist_id)
    SpotifyRetry::retry do
      begin
        playlist = RSpotify::Playlist.find_by_id(playlist_id)
      rescue RestClient::ResourceNotFound
        logger.warn("Playlist '#{playlist_id}' not found")
        next
      end
    end
  end

  def extract_track(track, tracks_added_at)
    added_at = tracks_added_at[track.id]

    artist_ids = track.artists.map { |artist| artist.id }.join(",")
    artist_names = track.artists.map { |artist| artist.name }.join(",")

    release_date = track.album.release_date
    release_date_precision = track.album.release_date_precision
    markets = (track.album.available_markets || []).join(",")

    [
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
