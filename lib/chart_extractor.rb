class ChartExtractor
  def create_chart(
    playlist_data_file,
    canonical_track_data_file,
    start_date,
    end_date,
    earliest_release_date,
    latest_release_date,
    output_path
  )
    playlist_data = CSV.read(playlist_data_file, headers: true)
    puts "Found #{playlist_data.length} lines in raw playlist data"

    canonical_data = CSV.read(canonical_track_data_file, headers: true)
    puts "Found #{canonical_data.length} lines in canonical track data"

    canonical_tracks = Hash.new

    canonical_data.each do |track|
      track_id = track["track_id"]
      canonical_tracks[track_id] = track
    end

    chart = Hash.new(0)

    nil_track_ids = playlist_data.filter { |track| track["track_id"].nil? }
    puts "Found #{nil_track_ids.length} tracks with nil ID"

    playlist_data.each do |add_event|
      date_added = Date.parse(add_event["added_at"])

      if (date_added >= start_date && date_added <= end_date)
        track_id = add_event["track_id"]
        canonical_track_id = canonical_tracks.fetch(track_id)["canonical_track_id"]

        chart[canonical_track_id] = chart[canonical_track_id] + 1
      end
    end

    chart_in_release_window = chart.filter { |track_id, count|
      track = canonical_tracks[track_id]
      # TODO: Handle month and year precisions
      track["release_date_precision"] == "day" &&
        Date.parse(track["release_date"]) >= earliest_release_date &&
        Date.parse(track["release_date"]) <= latest_release_date
    }

    CSV.open(output_path, "wb") do |csv|
      csv << [
        "track_id",
        "total_adds",
        "full_name",
        "artist_ids",
        "artist_names",
        "release_date",
        "release_date_precision",
        "available_markets",
      ]

      chart_in_release_window.sort_by {|k, v| -v}.each do |track_id, count|
        track = canonical_tracks[track_id]
        puts "Track '#{track['full_name']}' was released on '#{track['release_date']}'"

        csv << [
          track_id,
          count,
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
