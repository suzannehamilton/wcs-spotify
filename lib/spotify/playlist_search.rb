class PlaylistSearch
  def initialize(batch_size: 50)
    @batch_size = batch_size
    @logger = Logging.logger[self]
  end

  def search_playlists(search_term)
    found_all_results = false
    offset = 0

    results = []

    while !found_all_results
      @logger.info "Searching for '#{search_term}' with offset #{offset}"

      result_set = RSpotify::Playlist.search(search_term, limit: batch_size, offset: offset)

      filtered_results = result_set.select { |p| matches_term?(p, search_term) }

      results.concat(filtered_results)

      offset += batch_size
      found_all_results = result_set.length < batch_size
    end

    results
  end

private

  attr_reader :batch_size

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
