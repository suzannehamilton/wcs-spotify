class CanonicalTrackFinder
  def find_tracks(playlist_data_file, output_file)
    playlist_data = CSV.read(playlist_data_file, headers: true)
    puts "Found #{playlist_data.length} lines"

    unique_tracks = playlist_data.uniq { |track| track["track_id"] }
    puts "Found #{unique_tracks.length} unique tracks"

    grouped_tracks = Hash.new { |h, k| h[k] = [] }

    unique_tracks.each do |track|
      key = {
        # TODO: De-duplicate tracks with similar titles
        name: track["full_name"],
        artists: track["artist_ids"].split(",").sort
      }

      grouped_tracks[key] << track
    end

    puts "Found #{grouped_tracks.size} de-duplicated tracks"

    grouped_tracks.take(10).each do |key, tracks|
      if tracks.size > 1
        puts "Key: #{key}"
        puts tracks.map { |t| t["full_name"] }
      end
    end
  end
end
