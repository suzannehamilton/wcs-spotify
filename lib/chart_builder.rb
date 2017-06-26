require "thor"

require_relative "playlist_creator"
require_relative "track_fetcher"

class ChartBuilder < Thor
  desc "fetch_tracks", "Find recent popular tracks"
  def fetch_tracks
    TrackFetcher.new.fetch_tracks
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

