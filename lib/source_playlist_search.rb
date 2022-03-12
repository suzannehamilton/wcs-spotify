require_relative "spotify/playlist_search"

class SourcePlaylistSearch
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def find_playlists(output_path)
    search_terms = [
      "wcs",
      "westcoastswing",
      "west coastswing",
      "westcoast swing",
      "west coast swing",
      "westie",
      "west coast swing music",
      "wcs music",
      "west coast swing blues",
      "wcs blues",
      "west coast swing beginner",
      "wcs beginner",
      "west coast swing slow",
      "wcs slow",
      "west coast swing fast",
      "wcs fast",
    ]

    # TODO: Reference file relative to this one?
    config = YAML::load_file("config.yaml")

    RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

    # TODO: Deduplicate playlist IDs
    wcs_playlists = search_terms.map { |term|
      @playlist_search.search_playlists(term)
    }.flatten

    CSV.open(output_path, "wb") do |csv|
      csv << [
        "id",
        "track_count",
        "name",
        "description",
      ]

      wcs_playlists.each do |playlist|
        csv << [
          playlist.id,
          playlist.total,
          playlist.name,
          playlist.description,
        ]
      end

      logger.info "Found #{wcs_playlists.length} playlists"
    end
  end

  private

    attr_reader :logger
end
