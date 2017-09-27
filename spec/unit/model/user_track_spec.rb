require_relative "../../../lib/model/user_track"

require "rspotify"

RSpec.describe UserTrack do
  describe "canonical track" do
    it "is nil if no instances are listed" do
      expect(UserTrack.new.canonical_track).to be_nil
    end

    it "is nil if instance has no ID" do
      user_track = UserTrack.new
      track_instance = RSpotify::Track.new

      user_track.update_adds(track_instance, "some_user_id", DateTime.new)

      expect(user_track.canonical_track).to be_nil
    end

    it "is the only instance if just one is listed" do
      user_track = UserTrack.new
      track_instance = RSpotify::Track.new("id" => "some_track_id")

      user_track.update_adds(track_instance, "some_user_id", DateTime.new)

      expect(user_track.canonical_track).to eq(track_instance)
    end

    it "is the only instance if several copies are listed" do
      user_track = UserTrack.new
      instance_1 = RSpotify::Track.new("id" => "some_track_id")
      instance_2 = RSpotify::Track.new("id" => "some_track_id")
      instance_3 = RSpotify::Track.new("id" => "some_track_id")

      user_track.update_adds(instance_1, "user_1", DateTime.new)
      user_track.update_adds(instance_2, "user_2", DateTime.new)
      user_track.update_adds(instance_3, "user_3", DateTime.new)

      expect(user_track.canonical_track.id).to eq("some_track_id")
    end

    # TODO: Test that UK+US version is selected
    # TODO: Test that UK is preferred over US
  end
end
