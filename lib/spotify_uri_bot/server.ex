defmodule SpotifyUriBot.Server do
  use GenServer

  require Logger

  alias SpotifyUriBot.Api
  alias SpotifyUriBot.Utils

  @retries 5

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

  def get_show(show_id) do
    GenServer.call(__MODULE__, {:show, show_id})
  end

  def get_episode(episode_id) do
    GenServer.call(__MODULE__, {:episode, episode_id})
  end

  def search(text) do
    GenServer.call(__MODULE__, {:search, text})
  end

  # Server callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:track, track_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, track_info} = Utils.retry_n(@retries, {&Api.get_track/2, [track_id, token]})
    {:reply, {:ok, track_info}, state}
  end

  def handle_call({:album, album_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, album_info} = Utils.retry_n(@retries, {&Api.get_album/2, [album_id, token]})
    {:reply, {:ok, album_info}, state}
  end

  def handle_call({:artist, artist_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, artist_info} = Utils.retry_n(@retries, {&Api.get_artist/2, [artist_id, token]})

    {:ok, top_tracks} =
      Utils.retry_n(@retries, {&Api.get_artist_top_tracks/2, [artist_id, token]})

    artist_info = Map.put(artist_info, :top_tracks, top_tracks)
    {:reply, {:ok, artist_info}, state}
  end

  def handle_call({:playlist, playlist_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, playlist_info} = Utils.retry_n(@retries, {&Api.get_playlist/2, [playlist_id, token]})
    {:reply, {:ok, playlist_info}, state}
  end

  def handle_call({:show, show_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, show_info} = Utils.retry_n(@retries, {&Api.get_show/2, [show_id, token]})
    {:reply, {:ok, show_info}, state}
  end

  def handle_call({:episode, episode_id}, _from, state) do
    {:ok, token} = Utils.retry_n(@retries, {&Api.get_token/0, []})
    {:ok, episode_info} = Utils.retry_n(@retries, {&Api.get_episode/2, [episode_id, token]})
    {:reply, {:ok, episode_info}, state}
  end

  def handle_call({:search, text}, _from, state) do
    with {search_type, search_query} <- Utils.get_search_type(text),
         {:ok, token} <- Utils.retry_n(@retries, {&Api.get_token/0, []}),
         {:ok, search_result} <-
           Utils.retry_n(@retries, {&Api.search/3, [search_query, [search_type], token]}) do
      {:reply, {:ok, search_type, search_result}, state}
    else
      err ->
        Logger.error("Error while searching: #{inspect(err)}")
        {:error, "No results"}
    end
  end
end
