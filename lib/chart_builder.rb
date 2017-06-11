require "thor"

require_relative "track_fetcher"

class ChartBuilder < Thor
  desc "fetch_tracks", "Find recent popular tracks"
  def fetch_tracks
    TrackFetcher.new.fetch_tracks
  end
end

