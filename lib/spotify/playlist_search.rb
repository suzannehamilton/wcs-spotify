class PlaylistSearch
  def initialize
    @logger = Logging.logger[self]
  end

  def search_playlists(search_term)
    found_all_results = false
    offset = 0
    set_size = 50

    results = []

    while !found_all_results
      @logger.info "Searching for '#{search_term}' with offset #{offset}"

      result_set = RSpotify::Playlist.search(search_term, limit: set_size, offset: offset)

      filtered_results = result_set.select { |p| matches_term?(p, search_term) }

      results.concat(result_set)

      offset += set_size
      found_all_results = result_set.length < set_size
    end

    results
  end

  # Spotify search results are too broad. For example, the search term "wcs"
  # matches playlists named "wc" which are very unlikely to be relevant. So only
  # include playlists whose name or description contain the exact search term.
  def matches_term?(playlist, search_term)
    term = search_term.downcase
    playlist.name.downcase.include?(term) ||
      (playlist.description && playlist.description.downcase.include?(term))
    rescue RestClient::ResourceNotFound
      @logger.warn "Could not find playlist #{playlist.uri}"
      false
  end
end
