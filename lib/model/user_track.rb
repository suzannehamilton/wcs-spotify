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
    valid_instances = @instances
      .uniq { |t| t.id }
      .reject { |t| t.id.nil? }

    TARGET_MARKET_PREFERENCES.each do |markets|
      available_instances = valid_instances
        .select { |t| is_available_in_markets?(t, markets) }
      return available_instances.max_by { |t| t.available_markets.count } unless available_instances.empty?
    end

    valid_instances.max_by { |t| t.available_markets.count }
  end

  def adds_in_date_range(from, to)
    added_by_user.values.select { |dates_added|
      earliest = dates_added.compact.min
      if earliest.nil?
        # Tracks with a nil `date-added` value were added to a playlist
        # before Spotify started storing date-added. So this is a valid
        # value but we can't use this track to generate charts.
        false
      else
        earliest >= from.to_time && earliest < to.to_time
      end
    }.length
  end

private
  def is_available_in_markets?(instance, markets)
    markets.all? { |m| instance.available_markets.include?(m) }
  end
end
