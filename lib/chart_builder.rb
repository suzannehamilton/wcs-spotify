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

  desc "diff_source_playlists PLAYLIST_1 PLAYLIST_2",
    "Find the difference between existing lists of playlist search results"
  def diff_source_playlists(playlist_1, playlist_2)
    output_path = "results/source_playlists/playlists_#{DateTime.now}.csv"

    playlist_combiner = PlaylistCombiner.new
    playlist_combiner.diff(playlist_1, playlist_2, output_path)

    puts "Playlists diffed and saved to #{output_path}"
    IO.popen("pbcopy", "w") { |pipe| pipe.puts output_path }
  end

  desc "fetch_source_tracks PLAYLIST_DATA_FILE", "Find tracks from all West Coast Swing playlists"
  option :in_progress
  def fetch_source_tracks(source_playlists_path)
    output_path = options[:in_progress] || "results/raw_playlist_data/tracks_#{DateTime.now}.csv"

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

  desc "extract_chart PLAYLIST_DATA_FILE CANONICAL_TRACK_FILE START_DATE END_DATE EARLIEST_RELEASE_DATE [LATEST_RELEASE_DATE]",
    "Calculate a chart between two dates"
  def extract_chart(playlist_data, canonical_track_data, start_date, end_date, earliest_release_date, latest_release_date=Date.today.to_s)
    output_path = "results/charts/chart_from_#{start_date}_to_#{end_date}_#{DateTime.now}.csv"

    chart_extractor = ChartExtractor.new
    chart_extractor.create_chart(
      playlist_data,
      canonical_track_data,
      Date.parse(start_date),
      Date.parse(end_date),
      Date.parse(earliest_release_date),
      Date.parse(latest_release_date),
      output_path
    )

    puts "Output saved to #{output_path}"
  end

  option :recent, :type => :boolean
  desc "monthly_chart PLAYLIST_DATA_FILE CANONICAL_TRACK_FILE MONTH",
    "Calculate a chart for a given month, e.g. '2022-05'"
  def monthly_chart(playlist_data, canonical_track_data, month)
    start_date = Date.strptime(month, "%Y-%m")
    end_date = start_date.next_month.prev_day
    earliest_release_date = if options[:recent]
      start_date.prev_month(2)
    else
      Date.new(1900, 1, 1)
    end

    output_path = "results/charts/chart_from_#{start_date}_to_#{end_date}_#{DateTime.now}.csv"

    chart_extractor = ChartExtractor.new
    chart_extractor.create_chart(
      playlist_data,
      canonical_track_data,
      start_date,
      end_date,
      earliest_release_date,
      output_path
    )

    puts "Output saved to #{output_path}"
  end

  option :size, :type => :numeric
  desc "create_playlist CHART_DATA_FILE TITLE DESCRIPTION",
    "Create a Spotify playlist for a chart"
  def create_playlist(chart_data_file, title, description)
    size = options[:size] || 40
    playlist(chart_data_file, title, description, size)
  end

  option :recent, :type => :boolean
  desc "monthly_playlist PLAYLIST_DATA_FILE CANONICAL_TRACK_FILE MONTH",
    "Create a playlist for a given month, e.g. '2022-05'"
  def monthly_playlist(playlist_data, canonical_track_data, month)
    start_date = Date.strptime(month, "%Y-%m")
    end_date = start_date.next_month.prev_day
    earliest_release_date = if options[:recent]
      start_date.prev_month(2)
    else
      Date.new(1900, 1, 1)
    end

    output_path = "results/charts/chart_from_#{start_date}_to_#{end_date}_#{DateTime.now}.csv"

    chart_extractor = ChartExtractor.new
    chart_extractor.create_chart(
      playlist_data,
      canonical_track_data,
      start_date,
      end_date,
      earliest_release_date,
      output_path
    )

    puts "Chart output saved to #{output_path}"

    formatted_month = start_date.strftime('%B %Y')
    title = if options[:recent]
      "Rising Westie Charts: #{formatted_month}"
    else
      "Westie Charts: #{formatted_month}"
    end
    description = if options[:recent]
      "Top new West Coast Swing tracks for #{formatted_month}"
    else
      "Top West Coast Swing tracks for #{formatted_month}"
    end

    playlist(output_path, title, description, 40)
  end


    option :recent, :type => :boolean
    desc "annual_playlist PLAYLIST_DATA_FILE CANONICAL_TRACK_FILE YEAR",
      "Create a playlist for a given month, e.g. '2022-05'"
    def annual_playlist(playlist_data, canonical_track_data, year)
      start_date = Date.strptime(year, "%Y")
      end_date = start_date.next_year.prev_day
      earliest_release_date = if options[:recent]
        start_date.prev_month(1)
      else
        Date.new(1900, 1, 1)
      end

      output_path = "results/charts/chart_from_#{start_date}_to_#{end_date}_#{DateTime.now}.csv"

      chart_extractor = ChartExtractor.new
      chart_extractor.create_chart(
        playlist_data,
        canonical_track_data,
        start_date,
        end_date,
        earliest_release_date,
        output_path
      )

      puts "Chart output saved to #{output_path}"

      formatted_year = start_date.strftime('%Y')
      title = if options[:recent]
        "Westie Charts (new songs): #{formatted_year}"
      else
        "Westie Charts: #{formatted_year}"
      end
      description = if options[:recent]
        "Top new West Coast Swing tracks for #{formatted_year}"
      else
        "Top West Coast Swing tracks for #{formatted_year}"
      end

      playlist(output_path, title, description, 200)
    end

private

  def playlist(chart_data_file, title, description, chart_size)
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
      description,
      chart_size
    )
  end
end
