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

    max_key, max_tracks = grouped_tracks.max_by { |key, tracks| tracks.size }

    puts max_key
    puts max_tracks.size
  end
end
