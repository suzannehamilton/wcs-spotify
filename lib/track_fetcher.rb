#!/usr/bin/env ruby

# TODO: Tidy requires
require "retriable"
require "rspotify"
require "yaml"
require "csv"

require_relative "chart_results"
require_relative "model/track_with_dates"
require_relative "model/user_track"
require_relative "spotify/playlist_search"

class TrackFetcher
  def initialize
    @logger = Logging.logger[self]
    @playlist_search = PlaylistSearch.new
  end

  def fetch_tracks(results_path)
    now = DateTime.now

    first_added_tracks = YAML.load_file(results_path).map { |t| DeserializedTrack.new(t) }

    logger.info "Found #{first_added_tracks.length} unique tracks"

    month_end = DateTime.new(now.year, now.month, 1, 0, 0, 0, 0)
    month_beginning = month_end << 1

    logger.info "Finding tracks for #{month_beginning.strftime("%Y_%B")}"

    monthly_tracks = top_tracks(first_added_tracks, month_beginning, month_end)

    rising_tracks = rising_tracks(first_added_tracks, month_beginning, month_end)

    year = now.year
    logger.info "Finding tracks for #{year}"
    year_end = DateTime.new(year + 1, 1, 1, 0, 0, 0, 0)
    year_beginning = DateTime.new(year, 1, 1, 0, 0, 0, 0)

    yearly_tracks = top_tracks(first_added_tracks, year_beginning, year_end)

    all_tracks = top_tracks(first_added_tracks, DateTime.new(1900), DateTime.now)

    ChartResults.new(
      yearly_tracks,
      monthly_tracks,
      rising_tracks,
      all_tracks,
      year_beginning,
      month_beginning,
      now)
  end

private

  attr_reader :logger

  ChartTrack = Struct.new(:track, :score)

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
        month_ending = to
        month_beginning = from
        (3).times do
          month_ending = month_beginning
          month_beginning = month_beginning << 1

          old_adds = user_track.adds_in_date_range(month_beginning, month_ending)
          previous_max = old_adds if old_adds > previous_max
        end

        early_date = DateTime.new(2008, 1, 1)
        earlier_adds = user_track.adds_in_date_range(early_date, month_beginning)

        if earlier_adds == 0
          score = rising_track_score(previous_max, current_adds)
          ChartTrack.new(canonical_track, score)
        else
          nil
        end
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

CanonicalTrack = Struct.new(:id, :name, :artists)

# TODO: Test
# TODO: Rename
class DeserializedTrack
  attr_reader :canonical_track

  def initialize(hash)
    @first_added_dates = hash[:first_added].map { |d| Date.parse(d) }
    @canonical_track = CanonicalTrack.new(hash[:id], hash[:name], hash[:artists])
  end

  def adds_in_date_range(from, to)
    @first_added_dates.select { |date|
      date >= from.to_date && date < to.to_date
    }.length
  end
end
