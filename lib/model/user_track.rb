class UserTrack
  attr_reader :added_by_user

  TARGET_MARKET_PREFERENCES = [["GB", "US"], ["GB"], ["US"]].freeze

  def initialize
    @instances = []
    @added_by_user = Hash.new { |h, k| h[k] = [] }
  end

  def update_adds(instance, user_id, added_at)
    @instances << instance
    added_by_user[user_id] << added_at
  end

  def canonical_track
    TARGET_MARKET_PREFERENCES.each do |markets|
      available_instances = valid_instances
        .select { |t| is_available_in_markets?(t, markets) }
      return available_instances.max_by { |t| t.available_markets.count } unless available_instances.empty?
    end

    valid_instances.max_by { |t| t.available_markets.count }
  end

  def first_release
    # TODO: Refine when comparing partial dates, so that '2007' doesn't come
    # before '2007-06-01'
    valid_instances
      .select { |t| t.album && t.album.release_date }
      .sort { |t1, t2| release_date(t1.album) <=> release_date(t2.album) }
      .first
  end

private
  def is_available_in_markets?(instance, markets)
    markets.all? { |m| instance.available_markets.include?(m) }
  end

  def valid_instances
    @_valid_instances ||= @instances
      .uniq { |t| t.id }
      .reject { |t| t.id.nil? }
  end

  def release_date(album)
    if album.release_date_precision == 'year'
      DateTime.strptime(album.release_date, '%Y')
    elsif album.release_date_precision == 'month'
      DateTime.strptime(album.release_date, '%Y-%m')
    else
      DateTime.strptime(album.release_date, '%Y-%m-%d')
    end
  end
end
