#!/usr/bin/env ruby

require "csv"
require "net/http"
require "rspotify"
require "yaml"

config = YAML::load_file("config.yaml")
client_id = config["spotify_api"]["client_id"]
client_secret = config["spotify_api"]["client_secret"]
RSpotify.authenticate(client_id, client_secret)

redirect_uri = "http://localhost/callback/"

# Perform OAuth without a webserver
puts "Visit this URL:"
puts "https://accounts.spotify.com/authorize?client_id=#{client_id}" +
  "&response_type=code&redirect_uri=#{redirect_uri}" +
  "&scope=playlist-modify-public playlist-modify-private"
puts "And enter the authorization code returned:"
auth_code = gets.strip

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

user_uri = URI("https://api.spotify.com/v1/me")
user_request = Net::HTTP::Get.new(user_uri, "Authorization" => "Bearer #{tokens['access_token']}")
user_https = Net::HTTP.new(user_uri.hostname, user_uri.port)
user_https.use_ssl = true
user_response = user_https.request(user_request)
authenticated_user = JSON.parse(user_response.body)

user = RSpotify::User.new(authenticated_user.merge("credentials" => credentials))

ChartTrack = Struct.new(:id, :adds, :title, :artist_names)
chart_tracks = []

CSV.foreach("results/year_so_far_2017_2017-06-01_20:11:03.csv", headers: :first_row) do |row|
  chart_tracks << ChartTrack.new(row["track_id"], row["adds"], row["name"], row["artists"])
end

chart_size = 40

top_tracks = chart_tracks.take(chart_size)
tracks_tied_for_last_place = chart_tracks[chart_size..-1].select { |t| t.adds == top_tracks.last.adds }
chart = top_tracks + tracks_tied_for_last_place

spotify_tracks = RSpotify::Track.find(chart.map { |t| t.id })

chart_playlist = user.create_playlist!("Westie Charts: 2017 so far", public: false)
chart_playlist.change_details!(description: "Top West Coast Swing tracks for the year so far")
chart_playlist.add_tracks!(spotify_tracks)

require 'pry'; binding.pry
