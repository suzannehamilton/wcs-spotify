require_relative 'spotify_retry'

class PlaylistSearch
  def initialize(batch_size: 50)
    @batch_size = batch_size
    @logger = Logging.logger[self]
  end

  def search_playlists(search_term, base_terms)
    found_all_results = false
    offset = 0
    # The Spotify search API now returns an HTTP 400 error when the offset is
    # too high
    max_offset = 1000

    results = []

    while !found_all_results && offset < max_offset
      @logger.info "Searching for '#{search_term}' with offset #{offset}"

      result_set = SpotifyRetry::retry do
        begin
          RSpotify::Playlist.search(search_term, limit: batch_size, offset: offset)
        rescue RestClient::ResourceNotFound
          @logger.warn "Could not get search results for term '#{search_term}' with offset #{offset} and batch size #{batch_size}"
          []
        end
      end

      filtered_results = result_set.select { |p|
        matches_term?(p, base_terms)
      }

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
  def matches_term?(playlist, base_terms)
    base_terms.any? { |term|
      playlist.name.downcase.include?(term) ||
        (playlist.description && playlist.description.downcase.include?(term))
    }
    rescue RestClient::ResourceNotFound
      @logger.warn "Could not find playlist #{playlist.uri}"
      false
  end
end
