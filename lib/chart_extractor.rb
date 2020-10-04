class ChartExtractor
  def create_chart(
    playlist_data_file,
    canonical_track_data_file,
    start_date,
    end_date
  )

    playlist_data = CSV.read(playlist_data_file, headers: true)
    puts "Found #{playlist_data.length} lines in raw playlist data"

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
