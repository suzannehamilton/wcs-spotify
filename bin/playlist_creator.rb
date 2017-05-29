#!/usr/bin/env ruby

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

base_user = RSpotify::User.find('westiecharts')
user = RSpotify::User.new(
  "id" => 'westiecharts',
  "credentials" => credentials,
  "href" => base_user.href,
  "type" => base_user.type,
  "external_urls" => base_user.external_urls,
  "uri" => base_user.uri)

new_playlist = user.create_playlist!("some-playlist", public: false)
require 'pry'; binding.pry

