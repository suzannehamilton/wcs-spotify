require_relative "../../../lib/spotify/playlist_search"

require "rspotify"

RSpec.describe PlaylistSearch do
  BATCH_SIZE = 3.freeze

  before(:all) do
    @playlist_search = PlaylistSearch.new(batch_size: BATCH_SIZE)
  end

  it "returns empty results if there are no matching playlists" do
    rspotify_playlist = class_double("RSpotify::Playlist").as_stubbed_const
    raw_results = []
    allow(rspotify_playlist).to receive(:search)
      .with("some search term", limit: BATCH_SIZE, offset: 0)
      .and_return(raw_results)

    search_results = @playlist_search.search_playlists("some search term")
    expect(search_results).to eq([])
  end

  it "returns all playlists if there is a single page of results" do
    raw_results = [
      RSpotify::Playlist.new("name" => "Playlist 1", "tracks" => {}),
      RSpotify::Playlist.new("name" => "Playlist 2", "tracks" => {}),
    ]
    rspotify_playlist = class_double("RSpotify::Playlist").as_stubbed_const
    allow(rspotify_playlist).to receive(:search)
      .with("playlist", limit: BATCH_SIZE, offset: 0)
      .and_return(raw_results)

    search_results = @playlist_search.search_playlists("playlist")
    expect(search_results).to eq(raw_results)
  end

  it "combines all pages of results" do
    playlist_1 = RSpotify::Playlist.new("name" => "Playlist 1", "tracks" => {})
    playlist_2 = RSpotify::Playlist.new("name" => "Playlist 2", "tracks" => {})
    playlist_3 = RSpotify::Playlist.new("name" => "Playlist 3", "tracks" => {})
    playlist_4 = RSpotify::Playlist.new("name" => "Playlist 4", "tracks" => {})
    playlist_5 = RSpotify::Playlist.new("name" => "Playlist 5", "tracks" => {})

    page_1 = [playlist_1, playlist_2, playlist_3]
    page_2 = [playlist_4, playlist_5]

    rspotify_playlist = class_double("RSpotify::Playlist").as_stubbed_const
    allow(rspotify_playlist).to receive(:search)
      .with("playlist", limit: BATCH_SIZE, offset: 0)
      .and_return(page_1)
    allow(rspotify_playlist).to receive(:search)
      .with("playlist", limit: BATCH_SIZE, offset: 3)
      .and_return(page_2)

    search_results = @playlist_search.search_playlists("playlist")
    expect(search_results).to eq([
      playlist_1,
      playlist_2,
      playlist_3,
      playlist_4,
      playlist_5,
    ])
  end

  it "excludes playlists which do not match the search term exactly" do
    playlist_1 = RSpotify::Playlist.new("name" => "AbCd", "tracks" => {})
    playlist_2 = RSpotify::Playlist.new(
      "name" => "some other name",
      "description" => "some description",
      "tracks" => {}
    )
    playlist_3 = RSpotify::Playlist.new("name" => "a name which abcd includes the term", "tracks" => {})
    playlist_4 = RSpotify::Playlist.new("name" => "ab cd", "tracks" => {})
    playlist_5 = RSpotify::Playlist.new(
      "name" => "yet another name",
      "description" => "a description with ABCD",
      "tracks" => {}
    )

    page_1 = [playlist_1, playlist_2, playlist_3]
    page_2 = [playlist_4, playlist_5]

    rspotify_playlist = class_double("RSpotify::Playlist").as_stubbed_const
    allow(rspotify_playlist).to receive(:search)
      .with("abCD", limit: BATCH_SIZE, offset: 0)
      .and_return(page_1)
    allow(rspotify_playlist).to receive(:search)
      .with("abCD", limit: BATCH_SIZE, offset: 3)
      .and_return(page_2)

    search_results = @playlist_search.search_playlists("abCD")
    expect(search_results).to eq([playlist_1, playlist_3, playlist_5])
  end
end
