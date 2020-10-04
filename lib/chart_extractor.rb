class ChartExtractor
  def create_chart(
    playlist_data_file,
    canonical_track_data_file,
    start_date,
    end_date
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

    puts "Built track lookup hash of #{canonical_data.length} tracks"

    chart = Hash.new(0)

    playlist_data.each do |add_event|
      date_added = Date.parse(add_event["added_at"])

      if (date_added >= start_date && date_added <= end_date)
        track_id = add_event["track_id"]
        canonical_track_id = canonical_tracks.fetch(track_id)["canonical_track_id"]

        chart[canonical_track_id] = chart[canonical_track_id] + 1
      end
    end

    chart.sort_by {|k, v| -v}.take(40).each do |track_id, count|
      track = canonical_tracks[track_id]
      puts "#{count} #{track["full_name"]} - #{track["artist_names"]}"
    end
  end
end
