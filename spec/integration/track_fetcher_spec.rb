require_relative "../../lib/track_fetcher"

RSpec.describe TrackFetcher do
  it "finds no tracks if Spotify has no relevant playlists" do
    # TODO: Move to shared setup
    stub_request(:post, "https://accounts.spotify.com/api/token")
      .with(body: {"grant_type"=>"client_credentials"})
      .to_return(status: 200, body: "{}", headers: {})
    # TODO: Extract to fixture
    empty_playlist_response = %({
      "playlists" : {
        "href" : "https://api.spotify.com/v1/search?query=dafghafdhadvsb&type=playlist&market=GB&offset=0&limit=20",
        "items" : [ ],
        "limit" : 20,
        "next" : null,
        "offset" : 0,
        "previous" : null,
        "total" : 0
      }
    })
    # TODO: Inject playlist search terms
    stub_request(:get, /api.spotify.com\/v1\/search\?limit=50&offset=0&q=.+&type=playlist/)
      .to_return(status: 200, body: empty_playlist_response, headers: {})

    track_fetcher = TrackFetcher.new
    results = track_fetcher.fetch_tracks

    expect(results.yearly_tracks).to eq([])
    expect(results.monthly_tracks).to eq([])
  end

  # TODO: Test year and month are correct in results object
end
