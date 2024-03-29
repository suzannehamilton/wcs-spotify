class PlaylistCombiner
  def initialize
    @logger = Logging.logger[self]
  end

  def combine(playlist_path_1, playlist_path_2, output_path)
    playlists_1 = CSV.read(playlist_path_1, headers: true)
    puts "Found #{playlists_1.length} lines in playlist 1"

    playlists_2 = CSV.read(playlist_path_2, headers: true)
    puts "Found #{playlists_2.length} lines in playlist 2"

    playlists_by_id_1 = playlists_1.map { |playlist|
      [playlist["id"], playlist]
    }.to_h

    playlists_by_id_2 = playlists_2.map { |playlist|
      [playlist["id"], playlist]
    }.to_h

    playlist_ids_1 = Set.new(playlists_by_id_1.keys)
    playlist_ids_2 = Set.new(playlists_by_id_2.keys)

    in_1_but_not_2 = playlist_ids_1 - playlist_ids_2
    in_2_but_not_1 = playlist_ids_2 - playlist_ids_1

    puts "Found #{in_1_but_not_2.length} playlists in file 1 but not in file 2"
    puts "Found #{in_2_but_not_1.length} playlists in file 2 but not in file 1"

    combined = playlists_by_id_1.merge(playlists_by_id_2)

    CSV.open(output_path, "wb") do |csv|
      csv << [
        "id",
        "track_count",
        "name",
        "description",
      ]

      combined.each do |id, playlist|
        csv << [
          playlist["id"],
          playlist["track_count"],
          playlist["name"],
          playlist["description"],
        ]
      end

      logger.info "Saved #{combined.length} playlists"
    end
  end

  private

    attr_reader :logger
end
