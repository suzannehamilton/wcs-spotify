class CanonicalTrackFinder
  def find_tracks(playlist_data_file, output_file)
    playlist_data = CSV.read(playlist_data_file, headers: true)

    puts "Found #{playlist_data.length} lines"
  end
end
