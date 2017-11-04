#!/usr/bin/env ruby

require "csv"
require "net/http"
require "rspotify"
require "yaml"

class PlaylistCreator
  ChartTrack = Struct.new(:id, :score, :title, :artist_names)

  def initialize
    @logger = Logging.logger[self]
  end

  def create_playlist(auth_code)
    config = YAML::load_file("config.yaml")
    client_id = config["spotify_api"]["client_id"]
    client_secret = config["spotify_api"]["client_secret"]
    RSpotify.authenticate(client_id, client_secret)

    redirect_uri = "http://localhost/callback/"

    # Perform OAuth without a webserver
    auth_header = "Basic " + Base64.strict_encode64("#{client_id}:#{client_secret}")

    token_uri = URI("https://accounts.spotify.com/api/token")
    request = Net::HTTP::Post.new(
      token_uri,
      "Authorization" => auth_header)
    request.body = "grant_type=authorization_code&code=#{auth_code}&redirect_uri=#{redirect_uri}"

    https = Net::HTTP.new(token_uri.hostname, token_uri.port)
    https.use_ssl = true
    response = https.request(request)

    tokens = JSON.parse(response.body)
    credentials = {"refresh_token" => tokens["refresh_token"], "token" => tokens["access_token"]}

    base_user = RSpotify::User.find('westiecharts')
    user = RSpotify::User.new(
      "id" => 'westiecharts',
      "credentials" => credentials,
      "href" => base_user.href,
      "type" => base_user.type,
      "external_urls" => base_user.external_urls,
      "uri" => base_user.uri)

    chart_tracks = []

    CSV.foreach("results/rising_tracks_2017_October_2017-11-03_22\:22\:38.csv", headers: :first_row) do |row|
      chart_tracks << ChartTrack.new(row["track_id"], row["score"], row["name"], row["artists"])
    end

    chart_size = 40

    top_tracks = chart_tracks.take(chart_size)
    tracks_tied_for_last_place = chart_tracks[chart_size..-1].select { |t| t.score == top_tracks.last.score }
    chart = top_tracks + tracks_tied_for_last_place

    spotify_tracks = RSpotify::Track.find(chart.map { |t| t.id })

    playlist = user.create_playlist!("Westie Charts: July 2017", public: false)

    # Search for the playlist again. This is a workaround for a possible bug in
    # the Spotify API: when a playlist is created, the playlist's owner is not
    # populated correctly.
    chart_playlist = RSpotify::Playlist.find('westiecharts', playlist.id)
    chart_playlist.change_details!(description: "Top West Coast Swing tracks for July 2017")
    chart_playlist.add_tracks!(spotify_tracks)

    logger.info "Created playlist '#{playlist.id}'"
  end

private

  attr_reader :logger
end
