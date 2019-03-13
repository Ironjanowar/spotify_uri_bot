defmodule SpotifyUriBot.Server do
  use GenServer

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
end
