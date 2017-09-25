require_relative "../../lib/track_fetcher"

RSpec.describe TrackFetcher do
  before(:all) do
    stub_request(:post, "https://accounts.spotify.com/api/token")
      .with(body: {"grant_type"=>"client_credentials"})
      .to_return(status: 200, body: "{}", headers: {})
  end

  it "finds no tracks if Spotify has no relevant playlists" do
    empty_results = File.read("spec/fixtures/playlist_search/no_results.json")
    # TODO: Inject playlist search terms
    stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
      .to_return(status: 200, body: empty_results, headers: {})

    track_fetcher = TrackFetcher.new
    results = track_fetcher.fetch_tracks

    expect(results.yearly_tracks).to eq([])
    expect(results.monthly_tracks).to eq([])
  end

  # TODO: Test year and month are correct in results object
end
