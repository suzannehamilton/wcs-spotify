require_relative 'track_fetcher'

class TrackFilterer
  def filter_to_year(input_data_path, max_year)
    first_added_tracks = YAML.load_file(input_data_path).map { |t| DeserializedTrack.new(t) }
    puts "Starting with #{first_added_tracks.count} tracks"

    old_tracks = first_added_tracks
      .select { |track| !track.release_date.nil? }
      .select { |track|
        Date.strptime(track.release_date, "%Y").year <= max_year
      }
      .sort { |t1, t2| t2.total_adds <=> t1.total_adds }

    puts "Narrowed down to #{old_tracks.count} old tracks"

    popular_tracks = old_tracks.select { |track| track.total_adds > 10 }
    puts "Narrowed down to #{popular_tracks.count} popular tracks"

    output_path = "results/tracks/old_tracks_#{DateTime.now.strftime('%F_%T')}.yml"

    serialized_tracks = popular_tracks
      .map(&:serialize)

    File.open(output_path, "w") do |file|
      file.write serialized_tracks.to_yaml
    end

    puts "Tracks saved to #{output_path}"
  end
end
