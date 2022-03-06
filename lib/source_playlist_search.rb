class SourcePlaylistSearch
  def find_playlists(output_path)
    CSV.open(output_path, "wb") do |csv|
      csv << [
        "id",
        "name",
        "description",
      ]
    end
  end
end
