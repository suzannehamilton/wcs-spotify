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
      track_instance = RSpotify::Track.new(
        "id" => "some_track_id",
        "available_markets" => [])

      user_track.update_adds(track_instance, "some_user_id", DateTime.new)

      expect(user_track.canonical_track).to eq(track_instance)
    end

    it "selects one of several copies of an instance are listed" do
      user_track = UserTrack.new
      instance_1 = RSpotify::Track.new(
        "id" => "some_track_id",
        "available_markets" => [])
      instance_2 = RSpotify::Track.new(
        "id" => "some_track_id",
        "available_markets" => [])
      instance_3 = RSpotify::Track.new(
        "id" => "some_track_id",
        "available_markets" => [])

      user_track.update_adds(instance_1, "user_1", DateTime.new)
      user_track.update_adds(instance_2, "user_2", DateTime.new)
      user_track.update_adds(instance_3, "user_3", DateTime.new)

      expect(user_track.canonical_track.id).to eq("some_track_id")
    end

    it "is the internationally available instance if one exists" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      uk_instance = RSpotify::Track.new(
        "id" => "uk_instance",
        "available_markets" => ["GB"])
      us_instance = RSpotify::Track.new(
        "id" => "us_instance",
        "available_markets" => ["US"])
      international_instance = RSpotify::Track.new(
        "id" => "international_instance",
        "available_markets" => ["US", "GB"])
      other_instance = RSpotify::Track.new(
        "id" => "another_instance",
        "available_markets" => ["FR", "DE"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(uk_instance, "user_2", DateTime.new)
      user_track.update_adds(us_instance, "user_3", DateTime.new)
      user_track.update_adds(international_instance, "user_4", DateTime.new)
      user_track.update_adds(other_instance, "user_5", DateTime.new)

      expect(user_track.canonical_track).to eq(international_instance)
    end

    it "is the uk instance if there is no international instance" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      uk_instance = RSpotify::Track.new(
        "id" => "uk_instance",
        "available_markets" => ["GB"])
      us_instance = RSpotify::Track.new(
        "id" => "us_instance",
        "available_markets" => ["US"])
      other_instance = RSpotify::Track.new(
        "id" => "another_instance",
        "available_markets" => ["FR", "DE"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(uk_instance, "user_2", DateTime.new)
      user_track.update_adds(us_instance, "user_3", DateTime.new)
      user_track.update_adds(other_instance, "user_4", DateTime.new)

      expect(user_track.canonical_track).to eq(uk_instance)
    end

    it "is the uk instance if there is no international instance" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      uk_instance = RSpotify::Track.new(
        "id" => "uk_instance",
        "available_markets" => ["GB"])
      us_instance = RSpotify::Track.new(
        "id" => "us_instance",
        "available_markets" => ["US"])
      other_instance = RSpotify::Track.new(
        "id" => "another_instance",
        "available_markets" => ["FR", "DE"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(uk_instance, "user_2", DateTime.new)
      user_track.update_adds(us_instance, "user_3", DateTime.new)
      user_track.update_adds(other_instance, "user_4", DateTime.new)

      expect(user_track.canonical_track).to eq(uk_instance)
    end

    it "is the us instance if there is no uk instance" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      us_instance = RSpotify::Track.new(
        "id" => "us_instance",
        "available_markets" => ["US"])
      other_instance = RSpotify::Track.new(
        "id" => "another_instance",
        "available_markets" => ["FR", "DE"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(us_instance, "user_2", DateTime.new)
      user_track.update_adds(other_instance, "user_3", DateTime.new)

      expect(user_track.canonical_track).to eq(us_instance)
    end

    it "is the instance with most available markets if there is no uk or us instance" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      low_availability_instance = RSpotify::Track.new(
        "id" => "low_availability_instance",
        "available_markets" => ["FR", "DE"])
      high_availability_instance = RSpotify::Track.new(
        "id" => "high_availability_instance",
        "available_markets" => ["DK", "NO", "SE", "AU", "NZ"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(low_availability_instance, "user_2", DateTime.new)
      user_track.update_adds(high_availability_instance, "user_3", DateTime.new)

      expect(user_track.canonical_track).to eq(high_availability_instance)
    end

    it "is the instance with the most available markets if there are multiple UK/US instances" do
      user_track = UserTrack.new
      unavailable_instance = RSpotify::Track.new(
        "id" => "unavailable_instance",
        "available_markets" => [])
      uk_instance = RSpotify::Track.new(
        "id" => "uk_instance",
        "available_markets" => ["GB"])
      us_instance = RSpotify::Track.new(
        "id" => "us_instance",
        "available_markets" => ["US"])
      international_instance_1 = RSpotify::Track.new(
        "id" => "international_instance_1",
        "available_markets" => ["US", "GB", "FR", "NZ"])
      international_instance_2 = RSpotify::Track.new(
        "id" => "international_instance_2",
        "available_markets" => ["US", "GB"])
      international_instance_3 = RSpotify::Track.new(
        "id" => "international_instance_3",
        "available_markets" => ["US", "GB", "AU", "CA", "MX"])
      other_instance = RSpotify::Track.new(
        "id" => "another_instance",
        "available_markets" => ["FR", "DE"])

      user_track.update_adds(unavailable_instance, "user_1", DateTime.new)
      user_track.update_adds(uk_instance, "user_2", DateTime.new)
      user_track.update_adds(us_instance, "user_3", DateTime.new)
      user_track.update_adds(international_instance_1, "user_4", DateTime.new)
      user_track.update_adds(international_instance_2, "user_5", DateTime.new)
      user_track.update_adds(international_instance_3, "user_6", DateTime.new)
      user_track.update_adds(other_instance, "user_7", DateTime.new)

      expect(user_track.canonical_track).to eq(international_instance_3)
    end
  end
end
