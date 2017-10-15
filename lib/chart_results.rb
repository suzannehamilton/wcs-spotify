class ChartResults
  attr_reader :yearly_tracks,
    :monthly_tracks,
    :rising_tracks,
    :year_beginning,
    :month_beginning,
    :timestamp

  def initialize(
    yearly_tracks,
    monthly_tracks,
    rising_tracks,
    year_beginning,
    month_beginning,
    timestamp)
    @yearly_tracks = yearly_tracks
    @monthly_tracks = monthly_tracks
    @rising_tracks = rising_tracks
    @year_beginning = year_beginning
    @month_beginning = month_beginning
    @timestamp = timestamp
  end

  def save_year_chart
    save_tracks(yearly_tracks, "year_so_far_#{year_beginning.year}")
  end

  def save_month_chart
    save_tracks(monthly_tracks, "last_month_#{month_beginning.strftime('%Y_%B')}")
  end

  def save_rising_tracks_chart
    save_tracks(rising_tracks, "rising_tracks_#{month_beginning.strftime('%Y_%B')}")
  end

private

  def save_tracks(tracks, name)
    file_name = "results/#{name}_#{timestamp.strftime('%F_%T')}.csv"
    CSV.open(file_name, "wb") do |csv|
      csv << ["score", "track_id", "artists", "name"]
      tracks.each do |chart_track|
        track = chart_track.track
        artist_name = track.artists.map { |a| a.name }.join(", ")
        csv << [chart_track.score, track.id, artist_name, track.name]
      end
    end
  end
end
