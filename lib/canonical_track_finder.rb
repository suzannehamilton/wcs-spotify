class CanonicalTrackFinder
  def find_tracks(playlist_data_file, output_file)
    playlist_data = CSV.read(playlist_data_file, headers: true)
    puts "Found #{playlist_data.length} lines"

    grouped_tracks = Hash.new { |h, k| h[k] = [] }

    playlist_data.each do |track|
      key = {
        # TODO: De-duplicate tracks with similar titles
        name: track["full_name"],
        artists: track["artist_ids"].split(",").sort
      }

      grouped_tracks[key] << track
    end

    puts "Found #{grouped_tracks.size} de-duplicated tracks"
  end
end
