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

    puts "Built track lookup hash of  #{canonical_data.length} tracks"

    count = 0

    playlist_data.each do |add_event|
      date_added = Date.parse(add_event["added_at"])

      if (date_added >= start_date && date_added <= end_date)
        count = count + 1
      end
    end

    puts "Found #{count} adds in range"
  end
end
