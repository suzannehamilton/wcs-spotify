class UserTrack
  attr_reader :tracks, :added_by_user

  def initialize
    @tracks = []
    @added_by_user = Hash.new { |h, k| h[k] = [] }
  end

  def update_adds(track, user_id, added_at)
    tracks << track
    added_by_user[user_id] << added_at
  end

  def canonical_track
    tracks.reject { |t| t.id.nil? }
      .sort_by { |t| t.id }.first
  end
end
