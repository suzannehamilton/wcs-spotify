#!/usr/bin/env ruby

require "rspotify"
require "yaml"
require "csv"

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

    if track_id
      track = tracks[track_id] || UserTrack.new(playlist_track.track)
      tracks[track_id] = track

      user_id = playlist_track.owner.id
      track.added_by_user[user_id] << playlist_track.added_at
    else
      # Tracks with no IDs are from the user's local filesystem
    end
  end
end

ChartTrack = Struct.new(:track, :adds)

def tracks_added_in(user_tracks, from, to)
  tracks_in_range = []

  user_tracks.each { |id, user_track|
    adds = user_track.added_by_user.values.select { |dates_added|
      earliest = dates_added.compact.min
      if earliest.nil?
        # Tracks with a nil `date-added` value were added to a playlist
        # before Spotify started storing date-added. So this is a valid
        # value but we can't use this track to generate charts.
        false
      else
        earliest >= from.to_time && earliest < to.to_time
      end
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

def save_tracks(chart, name, current_time)
  file_name = "results/#{name}_#{current_time.strftime('%F_%T')}.csv"
  CSV.open(file_name, "wb") do |csv|
    csv << ["adds", "track_id", "artists", "name"]
    chart.each do |chart_track|
      track = chart_track.track
      artist_name = track.artists.map { |a| a.name }.join(", ")
      csv << [chart_track.adds, track.id, artist_name, track.name]
    end
  end
end

# TODO: Reference file relative to this one?
config = YAML::load_file("config.yaml")

RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

now = DateTime.now

wcs_playlists = search_terms.map { |term|
  search_playlists(term)
}.flatten

puts "Found #{wcs_playlists.length} playlists "

all_tracks = fetch_tracks(wcs_playlists)

puts "Found #{all_tracks.length} playlist tracks"

user_tracks = combine_tracks_by_user(all_tracks)

puts "Found #{user_tracks.length} unique tracks"

earliest_add_date = user_tracks.values.map { |t| t.added_by_user.values }.flatten.compact.min

month_end = DateTime.new(now.year, now.month, 1, 0, 0, 0, 0)
month_beginning = month_end << 1

while month_beginning.to_time > earliest_add_date do
  puts "Finding tracks for #{month_beginning.strftime("%Y_%B")}"

  monthly_tracks = top_tracks(user_tracks, month_beginning, month_end)
  save_tracks(monthly_tracks, "all_months_" + month_beginning.strftime("%Y_%B"), now)

  month_end = month_beginning
  month_beginning = month_end << 1
end

year = now.year

while year >= earliest_add_date.year do
  puts "Finding tracks for #{year}"
  year_end = DateTime.new(year + 1, 1, 1, 0, 0, 0, 0)
  year_beginning = DateTime.new(year, 1, 1, 0, 0, 0, 0)

  yearly_tracks = top_tracks(user_tracks, year_beginning, year_end)
  save_tracks(yearly_tracks, "all_years_#{year}", now)

  year = year - 1
end
