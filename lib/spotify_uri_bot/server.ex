defmodule SpotifyUriBot.Server do
  use GenServer

  require Logger

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_track(track_id) do
    GenServer.call(__MODULE__, {:track, track_id})
  end

  def get_album(album_id) do
    GenServer.call(__MODULE__, {:album, album_id})
  end

  def get_artist(artist_id) do
    GenServer.call(__MODULE__, {:artist, artist_id})
  end

  def get_playlist(playlist_id) do
    GenServer.call(__MODULE__, {:playlist, playlist_id})
  end

  def search(query) do
    GenServer.call(__MODULE__, {:search, query})
  end

  # Server callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:track, track_id}, _from, state) do
    {:ok, token} = SpotifyUriBot.Api.get_token()
    {:ok, track_info} = SpotifyUriBot.Api.get_track(track_id, token)
    {:reply, {:ok, track_info}, state}
  end

  def handle_call({:album, album_id}, _from, state) do
    {:ok, token} = SpotifyUriBot.Api.get_token()
    {:ok, album_info} = SpotifyUriBot.Api.get_album(album_id, token)
    {:reply, {:ok, album_info}, state}
  end

  def handle_call({:artist, artist_id}, _from, state) do
    {:ok, token} = SpotifyUriBot.Api.get_token()
    {:ok, artist_info} = SpotifyUriBot.Api.get_artist(artist_id, token)
    {:ok, top_tracks} = SpotifyUriBot.Api.get_artist_top_tracks(artist_id, token)
    artist_info = Map.put(artist_info, :top_tracks, top_tracks)
    {:reply, {:ok, artist_info}, state}
  end

  def handle_call({:playlist, playlist_id}, _from, state) do
    {:ok, token} = SpotifyUriBot.Api.get_token()
    {:ok, playlist_info} = SpotifyUriBot.Api.get_playlist(playlist_id, token)
    {:reply, {:ok, playlist_info}, state}
  end

  def handle_call({:search, query}, _from, state) do
    Logger.debug("Searching #{query}")
    {:ok, token} = SpotifyUriBot.Api.get_token()
    {:ok, %{body: body}} = SpotifyUriBot.Api.search(query, [:track], token)

    case Jason.decode(body) do
      {:ok, %{"tracks" => %{"items" => items}}} ->
        tracks = Enum.map(items, &SpotifyUriBot.Utils.extract_tracks_info/1)

        Logger.debug("Tracks result:\n#{inspect(tracks)}")
        {:reply, {:ok, tracks}, state}

      _ ->
        {:reply, {:ok, []}, state}
    end
  end
end
