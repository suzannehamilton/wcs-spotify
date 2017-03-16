#!/usr/bin/env ruby

require "rspotify"
require "yaml"

# TODO: Reinstate all the search terms
search_terms = [
  # "wcs",
  # "westcoastswing",
  # "west coastswing",
  # "westcoast swing",
  # "west coast swing",
  "west coast swing 2017",
]

def search_playlists(search_term)
  found_all_results = false
  offset = 0
  set_size = 50

  results = []

  while !found_all_results
    puts "Searching for '#{search_term}' with offset #{offset}"

    result_set = RSpotify::Playlist.search(search_term, limit: set_size, offset: offset)
    results.concat(result_set)

    offset += set_size
    found_all_results = result_set.length < set_size
  end

  results
end

PlaylistTrack = Struct.new(:track, :owner, :added_at)

def fetch_tracks(playlists)
  playlists.map { |playlist|
    total_tracks = playlist.total
    track_sets = (total_tracks / 100.to_f).ceil

    owner = playlist.owner

    playlist_tracks = []
    track_sets.times do |track_offset|
      track_set = playlist.tracks(offset: track_offset * 100)
      tracks_added_at = playlist.tracks_added_at

      playlist_tracks << track_set.map { |track|
        PlaylistTrack.new(
          track,
          owner,
          tracks_added_at[track.id]
        )
      }
    end

    playlist_tracks
  }.flatten
end

class UserTrack
  attr_reader :track, :added_by_user

  def initialize(track)
    @track = track
    @added_by_user = Hash.new { |h, k| h[k] = [] }
  end
end

def combine_tracks_by_user(playlist_tracks)
  playlist_tracks.each_with_object({}) do |playlist_track, tracks|
    track_id = playlist_track.track.id

    track = tracks[track_id] || UserTrack.new(playlist_track.track)
    tracks[track_id] = track

    user_id = playlist_track.owner.id
    track.added_by_user[user_id] << playlist_track.added_at
  end
end

ChartTrack = Struct.new(:track, :adds)

def tracks_added_in(user_tracks, from, to)
  tracks_in_range = []

  user_tracks.each { |id, user_track|
    adds = user_track.added_by_user.values.select { |dates_added|
      dates_added.any? {|d| d >= from && d < to }
    }.length

    if adds > 0
      tracks_in_range << ChartTrack.new(user_track.track, adds)
    end
  }

  tracks_in_range
end

def top_tracks(user_tracks, from, to)
  tracks_added_in(user_tracks, from, to)
    .sort_by { |chart_track| [-chart_track.adds, chart_track.track.id] }
end

def print_tracks(chart, number)
  chart.take(number).each_with_index do |chart_track, index|
    track = chart_track.track
    artist_name = track.artists.map { |a| a.name }.join(", ")
    puts "\##{index + 1} (#{chart_track.adds} adds) #{artist_name} - #{track.name}"
  end
end

# TODO: Reference file relative to this one?
config = YAML::load_file("config.yaml")

RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

wcs_playlists = search_terms.map { |term|
  search_playlists(term)
}.flatten

puts "Found #{wcs_playlists.length} playlists "

all_tracks = fetch_tracks(wcs_playlists)

puts "Found #{all_tracks.length} playlist tracks"

user_tracks = combine_tracks_by_user(all_tracks)

puts "Found #{user_tracks.length} unique tracks"

january_tracks = top_tracks(user_tracks, Time.new(2017, 1, 1, 0, 0, 0, 0), Time.new(2017, 2, 1, 0, 0, 0, 0))
february_tracks = top_tracks(user_tracks, Time.new(2017, 2, 1, 0, 0, 0, 0), Time.new(2017, 3, 1, 0, 0, 0, 0))
march_tracks = top_tracks(user_tracks, Time.new(2017, 3, 1, 0, 0, 0, 0), Time.new(2017, 4, 1, 0, 0, 0, 0))

tracks_2016 = top_tracks(user_tracks, Time.new(2016, 1, 1, 0, 0, 0, 0), Time.new(2017, 1, 1, 0, 0, 0, 0))
tracks_2017 = top_tracks(user_tracks, Time.new(2017, 1, 1, 0, 0, 0, 0), Time.new(2018, 1, 1, 0, 0, 0, 0))

require 'pry'; binding.pry
