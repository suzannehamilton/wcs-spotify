class UserTrack
  attr_reader :added_by_user

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
    return nil if valid_instances.empty?

    international_instances = valid_instances
      .select { |t| t.available_markets.include?("GB") && t.available_markets.include?("US") }
    return international_instances.max_by { |t| t.available_markets.count } if !international_instances.empty?

    uk_instance = valid_instances
      .select { |t| t.available_markets.include?("GB") }
      .first
    return uk_instance if uk_instance

    us_instance = valid_instances
      .select { |t| t.available_markets.include?("US") }
      .first
    return us_instance if us_instance

    valid_instances.max_by { |t| t.available_markets.count }
  end
end
