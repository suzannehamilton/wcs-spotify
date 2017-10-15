require "timecop"

require_relative "../../lib/track_fetcher"

RSpec.describe TrackFetcher do
  before(:all) do
    @track_fetcher = TrackFetcher.new
  end

  before(:each) do
    stub_request(:post, "https://accounts.spotify.com/api/token")
      .with(body: {"grant_type"=>"client_credentials"})
      .to_return(status: 200, body: "{}", headers: {})
  end

  it "finds no tracks if Spotify has no relevant playlists" do
    empty_results = File.read("spec/fixtures/playlist_search/no_results.json")
    # TODO: Inject playlist search terms
    stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
      .to_return(status: 200, body: empty_results, headers: {})

    results = @track_fetcher.fetch_tracks

    expect(results.yearly_tracks).to eq([])
    expect(results.monthly_tracks).to eq([])
  end

  it "generates a chart for the previous month" do
    empty_results = File.read("spec/fixtures/playlist_search/no_results.json")
    stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
      .to_return(status: 200, body: empty_results, headers: {})

    Timecop.freeze(DateTime.new(2015, 8, 24)) do
      results = @track_fetcher.fetch_tracks

      expect(results.month_beginning).to eq(DateTime.new(2015, 7, 1))
    end
  end

  it "generates a chart for the current year so far" do
    empty_results = File.read("spec/fixtures/playlist_search/no_results.json")
    stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
      .to_return(status: 200, body: empty_results, headers: {})

    Timecop.freeze(DateTime.new(2014, 3, 12)) do
      results = @track_fetcher.fetch_tracks

      expect(results.year_beginning).to eq(DateTime.new(2014, 1, 1))
    end
  end

  context "with playlist and track results" do
    before(:each) do
      playlist_search_results = File.read("spec/fixtures/playlist_search/results.json")
      stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
        .to_return(status: 200, body: playlist_search_results)

      playlist_1_response = File.read("spec/fixtures/playlists/playlist_1.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-1/playlists/18vMX5iVfT5kxEOagRnJte")
        .to_return(status: 200, body: playlist_1_response)
      playlist_2_response = File.read("spec/fixtures/playlists/playlist_2.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-2/playlists/5yYaaYjfZRhVElTxnBGIts")
        .to_return(status: 200, body: playlist_2_response)
      playlist_3_response = File.read("spec/fixtures/playlists/playlist_3.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-3/playlists/0HLIzKQFTK7a0Xg2z6mRnv")
        .to_return(status: 200, body: playlist_3_response)

      playlist_1_tracks = File.read("spec/fixtures/playlists/playlist_1_tracks.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-1/playlists/18vMX5iVfT5kxEOagRnJte/tracks?limit=100&offset=0")
        .to_return(status: 200, body: playlist_1_tracks)
      playlist_2_tracks = File.read("spec/fixtures/playlists/playlist_2_tracks.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-2/playlists/5yYaaYjfZRhVElTxnBGIts/tracks?limit=100&offset=0")
        .to_return(status: 200, body: playlist_2_tracks)
      playlist_3_tracks = File.read("spec/fixtures/playlists/playlist_3_tracks.json")
      stub_request(:get, "https://api.spotify.com/v1/users/some-user-3/playlists/0HLIzKQFTK7a0Xg2z6mRnv/tracks?limit=100&offset=0")
        .to_return(status: 200, body: playlist_3_tracks)

      Timecop.freeze(DateTime.new(2017, 10, 25))
    end

    after(:each) do
      Timecop.return
    end

    it "combines tracks into a monthly chart" do
      results = @track_fetcher.fetch_tracks

      monthly_tracks = results.monthly_tracks
      expect(monthly_tracks.count).to eq(15)
      expect(monthly_tracks[0].score).to eq(3)
      expect(monthly_tracks[0].track.id).to eq("0dA2Mk56wEzDgegdC6R17g")
    end

    it "combines tracks into a yearly chart" do
      results = @track_fetcher.fetch_tracks

      yearly_tracks = results.yearly_tracks
      expect(yearly_tracks.count).to eq(20)
      expect(yearly_tracks[0].score).to eq(3)
      expect(yearly_tracks[0].track.id).to eq("0dA2Mk56wEzDgegdC6R17g")
    end

    it "combines tracks into a monthly rising tracks chart" do
      results = @track_fetcher.fetch_tracks

      rising_tracks = results.rising_tracks
      expect(rising_tracks.count).to eq(15)
      expect(rising_tracks[0].score).to be > 0
      expect(rising_tracks[0].track.id).to eq("0dA2Mk56wEzDgegdC6R17g")
    end

    it "combines tracks added multiple times by the same user" do
      results = @track_fetcher.fetch_tracks

      yearly_tracks = results.yearly_tracks

      matching_tracks = yearly_tracks.select { |t| t.track.id == "70fdF045x3n1ahv7MG6Z4H" }
      expect(matching_tracks.count).to eq(1)
      expect(matching_tracks.first.score).to eq(1)
    end

    it "combines tracks with same title and artist but different IDs" do
      results = @track_fetcher.fetch_tracks

      yearly_tracks = results.yearly_tracks

      matching_tracks = yearly_tracks.select { |t| t.track.name == "Gooey" }
      expect(matching_tracks.count).to eq(1)
      expect(matching_tracks.first.score).to eq(2)
    end
  end
  # TODO: Test playlist and track scrolling. Possibly in unit tests.
end
