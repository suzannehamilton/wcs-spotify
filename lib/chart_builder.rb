require "logging"
require "thor"

require_relative "playlist_creator"
require_relative "track_downloader"
require_relative "track_fetcher"

class ChartBuilder < Thor
  Logging.logger.root.level = :info
  Logging.logger.root.appenders = [
    Logging.appenders.stdout("stdout"),
    Logging.appenders.file("log/chart_builder.log")
  ]

  desc "fetch_tracks", "Find recent popular tracks"
  def fetch_tracks
    # TODO: Tidy filename
    output_path = "results/tracks/tracks_#{DateTime.now}.yaml"

    track_downloader = TrackDownloader.new
    track_downloader.fetch_tracks(output_path)

    puts "Tracks saved to #{output_path}"
  end

  desc "build_chart TRACK_DATA", "Create a chart from track data"
  def build_chart(track_data)
    chart_results = TrackFetcher.new.fetch_tracks(track_data)
    chart_results.save_year_chart
    chart_results.save_month_chart
    chart_results.save_rising_tracks_chart
  end

  desc "create_playlist", "Create a Spotify playlist for a chart"
  def create_playlist
    # TODO: Pass config into PlaylistCreator
    config = YAML::load_file("config.yaml")
    client_id = config["spotify_api"]["client_id"]
    redirect_uri = "http://localhost/callback/"

    puts "Visit this URL:"
    puts "https://accounts.spotify.com/authorize?client_id=#{client_id}" +
      "&response_type=code&redirect_uri=#{redirect_uri}" +
      "&scope=playlist-modify-public playlist-modify-private"
    auth_code = ask("And enter the authorization code returned:").strip

    PlaylistCreator.new.create_playlist(auth_code)
  end
end
