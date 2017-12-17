require "yaml"

require_relative "../../lib/track_downloader"

# TODO: Rename back to TrackFetcher
RSpec.describe TrackDownloader do
  OUTPUT_DIRECTORY = "spec/test_output"

  before(:all) do
    Dir.mkdir OUTPUT_DIRECTORY unless File.exists?(OUTPUT_DIRECTORY)
  end

  before(:each) do
    stub_request(:post, "https://accounts.spotify.com/api/token")
      .with(body: {"grant_type"=>"client_credentials"})
      .to_return(status: 200, body: "{}", headers: {})
  end

  after(:each) do
    FileUtils.rm_rf("#{OUTPUT_DIRECTORY}/.", secure: true)
  end

  context "when Spotify has no relevant playlists" do
    before(:each) do
      empty_results = File.read("spec/fixtures/playlist_search/no_results.json")

      # TODO: Inject playlist search terms
      stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
        .to_return(status: 200, body: empty_results, headers: {})
    end

    it "finds no tracks" do
      described_class.new.fetch_tracks("#{OUTPUT_DIRECTORY}/no_results.yaml")

      results = YAML.load_file("#{OUTPUT_DIRECTORY}/no_results.yaml")
      expect(results).to be_empty
    end
  end

  context "when Spotify has relevant playlists" do
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

      described_class.new.fetch_tracks("#{OUTPUT_DIRECTORY}/results.yaml")

      @results = YAML.load_file("#{OUTPUT_DIRECTORY}/results.yaml")
    end

    it "includes all tracks" do
      expect(@results.count).to eq(21)
    end

    it "saves track details" do
      first_track = @results.first
      expect(first_track[:id]).to eq("7qiZfU4dY1lWllzX7mPBI3")
      expect(first_track[:name]).to eq("Shape of You")
      expect(first_track[:artists]).to eq("Ed Sheeran")
    end

    it "saves first-added dates" do
      first_track = @results.first
      expect(first_track[:first_added]).to contain_exactly(
        "2017-09-15",
        "2017-09-26",
      )

      second_track = @results[1]
      expect(second_track[:first_added]).to contain_exactly(
        "2017-09-03",
        "2017-09-26",
        "2017-09-26",
      )
    end
  end
end
