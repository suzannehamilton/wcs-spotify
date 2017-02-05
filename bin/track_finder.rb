#!/usr/bin/env ruby

require 'rspotify'

artists = RSpotify::Artist.search('Arctic Monkeys')
arctic_monkeys = artists.first

puts arctic_monkeys.name
