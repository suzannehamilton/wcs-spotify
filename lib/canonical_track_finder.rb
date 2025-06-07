require "date"

class CanonicalTrackFinder
  def find_tracks(playlist_data_file, output_path)
    playlist_data = CSV.read(playlist_data_file, headers: true)
    puts "Found #{playlist_data.length} lines"

    unique_tracks = playlist_data.uniq { |track| track["track_id"] }
    puts "Found #{unique_tracks.length} unique tracks"

    grouped_tracks = Hash.new { |h, k| h[k] = [] }

    unique_tracks.each do |track|
      key = {
        # TODO: De-duplicate tracks with similar titles
        name: track["full_name"].downcase,
        artists: track["artist_ids"].split(",").sort
      }

      grouped_tracks[key] << track
    end

    puts "Found #{grouped_tracks.size} de-duplicated tracks"

    CSV.open(output_path, "wb") do |csv|
      csv << [
        "track_id",
        "canonical_track_id",
        "full_name",
        "artist_ids",
        "artist_names",
        "release_date",
        "release_date_precision",
        "available_markets",
      ]

      grouped_tracks.each do |key, tracks|
        canonical_track = tracks.min_by { |track| release_date(track) }

        tracks.each do |track|
          csv << [
            track["track_id"],
            canonical_track["track_id"],
            track["full_name"],
            track["artist_ids"],
            track["artist_names"],
            track["release_date"],
            track["release_date_precision"],
            track["available_markets"],
          ]
        end
      end
    end
  end

private

  def release_date(track)
    rough_release_date = track["release_date"]

    if rough_release_date.nil?
      # TODO: Don't hack the date: Only use this track as the canonical track if it's the only one
      Date.today + 365
    elsif track["release_date_precision"] == "year"
      Date.strptime(rough_release_date, "%Y").next_year.prev_day
    elsif track["release_date_precision"] == "month"
      Date.strptime(rough_release_date, "%Y-%m").next_month.prev_day
    else
      Date.parse(rough_release_date)
    end
  end
end
