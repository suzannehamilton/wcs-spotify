class UserTrack
  attr_reader :tracks, :added_by_user

  def initialize
    @tracks = []
    @added_by_user = Hash.new { |h, k| h[k] = [] }
  end

  def canonical_track
    @tracks.reject { |t| t.id.nil? }
      .sort_by { |t| t.id }.first
  end
end
