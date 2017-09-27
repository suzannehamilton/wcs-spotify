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
    @instances.reject { |t| t.id.nil? }
      .sort_by { |t| t.id }.first
  end
end
