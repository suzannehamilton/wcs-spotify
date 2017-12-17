require "timecop"

require_relative "../../lib/track_fetcher"

RSpec.describe TrackFetcher do
  OUTPUT_DIRECTORY = "spec/test_output"
  FIXTURE_DIRECTORY = "spec/fixtures/track_adds"

  before(:all) do
    Dir.mkdir OUTPUT_DIRECTORY unless File.exists?(OUTPUT_DIRECTORY)
    @track_fetcher = TrackFetcher.new
  end

  after(:each) do
    FileUtils.rm_rf("#{OUTPUT_DIRECTORY}/.", secure: true)
  end

  # TODO: Use file input rather than Spotify request
  it "generates an empty chart if there are no tracks" do
    results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/no_tracks.yaml")

    expect(results.yearly_tracks).to eq([])
    expect(results.monthly_tracks).to eq([])
  end

  it "generates a chart for the previous month" do
    Timecop.freeze(DateTime.new(2015, 8, 24)) do
      results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/no_tracks.yaml")

      expect(results.month_beginning).to eq(DateTime.new(2015, 7, 1))
    end
  end

  it "generates a chart for the current year so far" do
    Timecop.freeze(DateTime.new(2014, 3, 12)) do
      results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/no_tracks.yaml")

      expect(results.year_beginning).to eq(DateTime.new(2014, 1, 1))
    end
  end

  context "with playlist and track results" do
    before(:each) do
      Timecop.freeze(DateTime.new(2017, 10, 25))
    end

    after(:each) do
      Timecop.return
    end

    it "combines tracks into a monthly chart" do
      results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/tracks.yaml")

      monthly_tracks = results.monthly_tracks
      expect(monthly_tracks.count).to eq(4)
      expect(monthly_tracks[0].score).to eq(3)
      expect(monthly_tracks[0].track.id).to eq("4iLqG9SeJSnt0cSPICSjxv")
    end

    it "combines tracks into a yearly chart" do
      results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/tracks.yaml")

      yearly_tracks = results.yearly_tracks
      expect(yearly_tracks.count).to eq(5)
      expect(yearly_tracks[0].score).to eq(8)
      expect(yearly_tracks[0].track.id).to eq("7qiZfU4dY1lWllzX7mPBI3")
    end

    it "combines tracks into a monthly rising tracks chart" do
      results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/tracks.yaml")

      rising_tracks = results.rising_tracks
      expect(rising_tracks.count).to eq(1)
      expect(rising_tracks[0].score).to be > 0
      expect(rising_tracks[0].track.id).to eq("4iLqG9SeJSnt0cSPICSjxv")
    end

    # TODO: Move these to track_downloader spec if necessary
    # it "combines tracks added multiple times by the same user" do
    #   results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/tracks.yaml")
    #
    #   yearly_tracks = results.yearly_tracks
    #
    #   matching_tracks = yearly_tracks.select { |t| t.track.id == "70fdF045x3n1ahv7MG6Z4H" }
    #   expect(matching_tracks.count).to eq(1)
    #   expect(matching_tracks.first.score).to eq(1)
    # end
    #
    # it "combines tracks with same title and artist but different IDs" do
    #   results = @track_fetcher.fetch_tracks("#{FIXTURE_DIRECTORY}/tracks.yaml")
    #
    #   yearly_tracks = results.yearly_tracks
    #
    #   matching_tracks = yearly_tracks.select { |t| t.track.name == "Gooey" }
    #   expect(matching_tracks.count).to eq(1)
    #   expect(matching_tracks.first.score).to eq(2)
    # end
  end
end
