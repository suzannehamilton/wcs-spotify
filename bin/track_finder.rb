#!/usr/bin/env ruby

require "rspotify"

search_terms = [
  "wcs",
  "westcoastswing",
  "west coastswing",
  "westcoast swing",
  "west coast swing",
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

wcs_playlists = search_terms.map { |term|
  search_playlists(term)
}.flatten

puts wcs_playlists.length

wcs_playlists.each do |playlist|
  puts "'#{playlist.name}' by '#{playlist.owner.id}'. #{playlist.total} tracks"
end
