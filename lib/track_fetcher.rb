#!/usr/bin/env ruby

require "retriable"
require "rspotify"
require "yaml"
require "csv"

require_relative "chart_results"
require_relative "model/user_track"
require_relative "spotify/playlist_search"

class TrackFetcher
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def fetch_tracks
    search_terms = [
      "wcs",
      "westcoastswing",
      "west coastswing",
      "westcoast swing",
      "west coast swing",
      "westie",
    ]

    # TODO: Reference file relative to this one?
    config = YAML::load_file("config.yaml")

    RSpotify.authenticate(config["spotify_api"]["client_id"], config["spotify_api"]["client_secret"])

    now = DateTime.now

    wcs_playlists = search_terms.map { |term|
      @playlist_search.search_playlists(term)
    }.flatten

    logger.info "Found #{wcs_playlists.length} playlists "

    all_tracks = fetch_tracks_for_playlists(wcs_playlists)

    logger.info "Found #{all_tracks.length} playlist tracks"

    user_tracks = combine_tracks_by_user(all_tracks)

    logger.info "Found #{user_tracks.length} unique tracks"

    month_end = DateTime.new(now.year, now.month, 1, 0, 0, 0, 0)
    month_beginning = month_end << 1

    logger.info "Finding tracks for #{month_beginning.strftime("%Y_%B")}"

    monthly_tracks = top_tracks(user_tracks, month_beginning, month_end)

    year = now.year
    logger.info "Finding tracks for #{year}"
    year_end = DateTime.new(year + 1, 1, 1, 0, 0, 0, 0)
    year_beginning = DateTime.new(year, 1, 1, 0, 0, 0, 0)

    yearly_tracks = top_tracks(user_tracks, year_beginning, year_end)

    ChartResults.new(yearly_tracks, monthly_tracks, year_beginning, month_beginning, now)
  end

private

  attr_reader :logger

  def get_playlist_tracks(playlist, offset)
    Retriable.retriable on: RestClient::RequestTimeout, tries: 3 do
      begin
        playlist.tracks(offset: offset)
      rescue RestClient::ResourceNotFound
        logger.warn "Could not find track for playlist '#{playlist.uri}' with offset #{offset}"
        []
      rescue URI::InvalidURIError
        logger.warn "Playlist '#{playlist.uri}' has invalid URI"
        []
      end
    end
  end

  def get_playlist_added_dates(playlist)
    Retriable.retriable on: RestClient::RequestTimeout, tries: 3 do
      begin
        return playlist.tracks_added_at
      rescue RestClient::ResourceNotFound
        logger.warn "Could not find track-added dates for playlist '#{playlist.uri}'"
        []
      rescue URI::InvalidURIError
        logger.warn "Playlist '#{playlist.uri}' has invalid URI"
        []
      end
    end
  end

  PlaylistTrack = Struct.new(:track, :owner, :added_at)

  def fetch_tracks_for_playlists(playlists)
    playlists.map { |playlist|
      total_tracks = playlist.total
      track_sets = (total_tracks / 100.to_f).ceil

      owner = playlist.owner

      playlist_tracks = []
      track_sets.times do |track_offset|
        track_set = get_playlist_tracks(playlist, track_offset * 100)
        tracks_added_at = get_playlist_added_dates(playlist)

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

  TrackId = Struct.new(:title, :artist_ids)

  def combine_tracks_by_user(playlist_tracks)
    playlist_tracks.each_with_object({}) do |playlist_track, tracks|
      title = playlist_track.track.name
      artist_ids = playlist_track.track.artists.map { |artist| artist.id }
      track_id = TrackId.new(title, artist_ids)

      tracks[track_id] ||= UserTrack.new
      tracks[track_id].tracks << playlist_track.track

      user_id = playlist_track.owner.id
      tracks[track_id].added_by_user[user_id] << playlist_track.added_at
    end
  end

  def choose_canonical_track(tracks)
    tracks.reject { |t| t.id.nil? }
      .sort_by { |t| t.id }.first
  end

  ChartTrack = Struct.new(:track, :adds)

  def tracks_added_in(user_tracks, from, to)
    tracks_in_range = []

    user_tracks.values.each { |user_track|
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
        canonical_track = choose_canonical_track(user_track.tracks)
        tracks_in_range << ChartTrack.new(canonical_track, adds) unless canonical_track.nil?
      end
    }

    tracks_in_range
  end

  def top_tracks(user_tracks, from, to)
    tracks_added_in(user_tracks, from, to)
      .sort_by { |chart_track| [-chart_track.adds, chart_track.track.id] }
  end
end
