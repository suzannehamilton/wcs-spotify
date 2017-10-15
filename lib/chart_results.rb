class ChartResults
  def initialize(rising_tracks, timestamp)
    @rising_tracks = rising_tracks
    @timestamp = timestamp
  end

  def save_rising_tracks_charts
    @rising_tracks.each do |date, tracks|
      save_tracks(tracks, "rising_tracks_#{date.strftime('%Y_%B')}")
    end
  end

private

  def save_tracks(tracks, name)
    file_name = "results/#{name}_#{@timestamp.strftime('%F_%T')}.csv"
    CSV.open(file_name, "wb") do |csv|
      csv << ["score", "previous_adds", "current_adds", "track_id", "artists", "name"]
      tracks.each do |chart_track|
        track = chart_track.track
        artist_name = track.artists.map { |a| a.name }.join(", ")
        csv << [
          chart_track.score,
          chart_track.previous_adds,
          chart_track.current_adds,
          track.id,
          artist_name,
          track.name]
      end
    end
  end
end
