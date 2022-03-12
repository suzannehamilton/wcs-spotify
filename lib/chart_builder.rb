require "logging"
require "thor"

require_relative "canonical_track_finder"
require_relative "chart_extractor"
require_relative "playlist_combiner"
require_relative "playlist_creator"
require_relative "source_playlist_search"
require_relative "source_track_fetcher"

class ChartBuilder < Thor
  Logging.logger.root.level = :info
  Logging.logger.root.appenders = [
    Logging.appenders.stdout("stdout"),
    Logging.appenders.file("log/chart_builder.log")
  ]

  desc "find_source_playlists", "Find existing playlists with West Coast Swing tracks"
  def find_source_playlists
    output_path = "results/source_playlists/playlists_#{DateTime.now}.csv"

    source_playlist_search = SourcePlaylistSearch.new
    source_playlist_search.find_playlists(output_path)

    puts "Source playlists saved to #{output_path}"
    IO.popen("pbcopy", "w") { |pipe| pipe.puts output_path }
  end

  desc "combine_source_playlists PLAYLIST_1 PLAYLIST_2",
    "Combine existing lists of playlist search results"
  def combine_source_playlists(playlist_1, playlist_2)
    output_path = "results/source_playlists/playlists_#{DateTime.now}.csv"

    playlist_combiner = PlaylistCombiner.new
    playlist_combiner.combine(playlist_1, playlist_2, output_path)

    puts "Playlists combined and saved to #{output_path}"
    IO.popen("pbcopy", "w") { |pipe| pipe.puts output_path }
  end

  desc "fetch_source_tracks", "Find tracks from all West Coast Swing playlists"
  def fetch_source_tracks(source_playlists_path)
    output_path = "results/raw_playlist_data/tracks_#{DateTime.now}.csv"

    source_track_fetcher = SourceTrackFetcher.new
    source_track_fetcher.fetch_tracks(source_playlists_path, output_path)

    puts "Output saved to #{output_path}"
  end

  desc "canonical PLAYLIST_DATA_FILE", "Find canonical tracks in a set of listening data"
  def canonical(playlist_data)
    output_path = "results/canonical/canonical_tracks_#{DateTime.now}.csv"

    canonical_track_finder = CanonicalTrackFinder.new
    canonical_track_finder.find_tracks(playlist_data, output_path)

    puts "Output saved to #{output_path}"
  end

  desc "extract_chart PLAYLIST_DATA_FILE CANONICAL_TRACK_FILE START_DATE END_DATE EARLIEST_RELEASE_DATE",
    "Calculate a chart between two dates"
  def extract_chart(playlist_data, canonical_track_data, start_date, end_date, earliest_release_date)
    output_path = "results/charts/chart_from_#{start_date}_to_#{end_date}_#{DateTime.now}.csv"

    chart_extractor = ChartExtractor.new
    chart_extractor.create_chart(
      playlist_data,
      canonical_track_data,
      Date.parse(start_date),
      Date.parse(end_date),
      Date.parse(earliest_release_date),
      output_path
    )

    puts "Output saved to #{output_path}"
  end

  desc "create_playlist CHART_DATA_FILE TITLE DESCRIPTION",
    "Create a Spotify playlist for a chart"
  def create_playlist(chart_data_file, title, description)
    # TODO: Pass config into PlaylistCreator
    config = YAML::load_file("config.yaml")
    client_id = config["spotify_api"]["client_id"]
    redirect_uri = "http://localhost/callback/"

    auth_url = "https://accounts.spotify.com/authorize?client_id=#{client_id}" +
      "&response_type=code&redirect_uri=#{redirect_uri}" +
      "&scope=playlist-modify-public%20playlist-modify-private"

    IO.popen("pbcopy", "w") { |pipe| pipe.puts auth_url }
    puts "Visit this URL (copied to clipboard):"
    puts auth_url

    auth_code = ask("And enter the authorization code returned:").strip

    PlaylistCreator.new.create_playlist(
      auth_code,
      chart_data_file,
      title,
      description
    )
  end
end
