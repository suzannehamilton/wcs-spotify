#!/usr/bin/env ruby

require "rspotify"

wcs_playlists = RSpotify::Playlist.search("WCS", limit: 50)
wcs_playlists.concat(RSpotify::Playlist.search("WCS", limit: 50, offset: 50))
wcs_playlists.concat(RSpotify::Playlist.search("WCS", limit: 50, offset: 100))
wcs_playlists.concat(RSpotify::Playlist.search("WCS", limit: 50, offset: 150))
wcs_playlists.concat(RSpotify::Playlist.search("WCS", limit: 50, offset: 200))
wcs_playlists.concat(RSpotify::Playlist.search("West Coast Swing", limit: 50))
wcs_playlists.concat(RSpotify::Playlist.search("West Coast Swing", limit: 50, offset: 50))
wcs_playlists.concat(RSpotify::Playlist.search("West Coast Swing", limit: 50, offset: 100))

puts wcs_playlists.length

wcs_playlists.each do |playlist|
  puts "'#{playlist.name}' by '#{playlist.owner.id}'. #{playlist.total} tracks"
end
