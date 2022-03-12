require_relative "spotify/playlist_search"

class SourcePlaylistSearch
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def find_playlists(output_path)
    base_terms = [
      "wcs",
      "w.c.s.",
      "w.c.s",
      "west coast swing",
      "westcoastswing",
      "westcoast swing",
      "west coastswing",
      "westie",
    ]

    additional_terms = [
      "beginner",
      "blues",
      "comp",
      "competition",
      "competitions",
      "fast",
      "medium",
      "music",
      "practice",
      "slow",
      "tracks",
    ]

    combined_terms = base_terms.flat_map { |base|
      additional_terms.map { |additional| "#{base} #{additional}" }
    }
    search_terms = base_terms + combined_terms

    # TODO: Reference file relative to this one?
    config = YAML::load_file("config.yaml")

    RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

    # TODO: Deduplicate playlist IDs
    wcs_playlists = search_terms.map { |term|
      @playlist_search.search_playlists(term, base_terms)
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
