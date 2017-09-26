class UserTrack
  attr_reader :tracks, :added_by_user

  def initialize
    @tracks = []
    @added_by_user = Hash.new { |h, k| h[k] = [] }
  end
end
