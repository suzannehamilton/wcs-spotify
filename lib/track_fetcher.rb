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

    rising_track_charts = {}

    24.times do
      logger.info "Finding rising tracks for #{month_beginning.strftime("%B %Y")}"

      rising_track_charts[month_beginning] = rising_tracks(user_tracks, month_beginning, month_end)

      month_end = month_beginning
      month_beginning = month_end << 1
    end

    ChartResults.new(rising_track_charts, now)
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
    playlist_tracks.each_with_object(Hash.new { |h, k| h[k] = UserTrack.new }) { |playlist_track, tracks|
      title = playlist_track.track.name
      artist_ids = playlist_track.track.artists.map { |artist| artist.id }
      track_id = TrackId.new(title, artist_ids)

      tracks[track_id].update_adds(
        playlist_track.track,
        playlist_track.owner.id,
        playlist_track.added_at
      )
    }.values
  end

  ChartTrack = Struct.new(:track, :score, :previous_adds, :current_adds)

  def tracks_added_in(user_tracks, from, to)
    user_tracks.map { |user_track|
      adds = user_track.adds_in_date_range(from, to)
      canonical_track = user_track.canonical_track

      if adds > 0 && canonical_track
        ChartTrack.new(canonical_track, adds)
      else
        nil
      end
    }.compact
  end

  def top_tracks(user_tracks, from, to)
    tracks_added_in(user_tracks, from, to)
      .sort_by { |chart_track| [-chart_track.score, chart_track.track.id] }
  end

  def rising_tracks(user_tracks, from, to)
    user_tracks.map { |user_track|
      current_adds = user_track.adds_in_date_range(from, to)
      canonical_track = user_track.canonical_track

      if current_adds > 0 && canonical_track
        previous_max = 0
        month_ending = from
        month_beginning = from << 1
        (3 * 12).times do
          old_adds = user_track.adds_in_date_range(month_beginning, month_ending)
          previous_max = old_adds if old_adds > previous_max

          month_ending = month_beginning
          month_beginning = month_beginning << 1
        end

        score = rising_track_score(previous_max, current_adds)
        ChartTrack.new(canonical_track, score, previous_max, current_adds)
      else
        nil
      end
    }.compact
      .sort_by { |rising_track| [-rising_track.score, rising_track.track.id] }
  end

  def rising_track_score(old_adds, current_adds)
    (current_adds - old_adds) * Math.sqrt(current_adds)
  end
end
