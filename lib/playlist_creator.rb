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

  def create_playlist(
    auth_code,
    chart_data_file,
    playlist_title,
    playlist_description,
    chart_size
  )
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

    CSV.foreach(chart_data_file, headers: :first_row) do |row|
      chart_tracks << ChartTrack.new(row["track_id"], row["total_adds"], row["full_name"], row["artist_names"])
    end

    top_tracks = chart_tracks.take(chart_size)
    tracks_tied_for_last_place = chart_tracks[chart_size..-1].select { |t| t.score == top_tracks.last.score }
    chart = top_tracks + tracks_tied_for_last_place

    track_ids = chart.map { |t| t.id }
    puts "Getting #{track_ids.count} tracks"

    spotify_tracks = track_ids
      .each_slice(50)
      .map { |batch| RSpotify::Track.find(batch) }
      .flatten

    puts "Creating playlist"

    playlist = user.create_playlist!(playlist_title, public: false)

    # Search for the playlist again. This is a workaround for a possible bug in
    # the Spotify API: when a playlist is created, the playlist's owner is not
    # populated correctly.
    chart_playlist = RSpotify::Playlist.find('westiecharts', playlist.id)
    chart_playlist.change_details!(description: playlist_description)

    spotify_tracks.each_slice(50) do |batch|
      chart_playlist.add_tracks!(batch)
    end

    logger.info "Created playlist '#{playlist.uri}' named '#{playlist_title}' with #{spotify_tracks.count} tracks"
    `echo #{playlist.uri} | pbcopy`
  end

private

  attr_reader :logger
end
