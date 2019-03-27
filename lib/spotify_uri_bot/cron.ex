defmodule SpotifyUriBot.Cron do
  use GenServer

  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def check_stats() do
    GenServer.cast(__MODULE__, :check_stats)
  end

  # Server callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast(:check_stats, state) do
    case state[:stats] do
      nil ->
        stats = SpotifyUriBot.Stats.get_stats()

        # Notify admins

        {:noreply, Map.put(:stats, stats)}

      stats ->
        new_stats = SpotifyUriBot.Stats.get_stats()
        {:noreply, new_stats}
    end
  end
end
