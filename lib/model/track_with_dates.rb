class TrackWithDates
  attr_reader :canonical_track

  def initialize(user_track)
    @canonical_track = user_track.canonical_track

    @first_added_dates = user_track.added_by_user.map { |user, dates_added|
      dates_added.compact.min
    }.compact
  end

  # TODO: Delete?
  def adds_in_date_range(from, to)
    @first_added_dates.select { |date|
      date >= from.to_time && date < to.to_time
    }.length
  end

  def serialize
    {
      id: @canonical_track.id,
      name: @canonical_track.name,
      artists: @canonical_track.artists.map{ |a| a.name }.join(", "),
      first_added: @first_added_dates.map { |d| d.strftime("%Y-%m-%d") },
    }
  end
end
