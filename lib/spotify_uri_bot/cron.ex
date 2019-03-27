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
        stats_message = SpotifyUriBot.Bot.generate_stats_message(stats)

        # Notify admins
        ExGram.Config.get(:spotify_uri_bot, :admins, [])
        |> Enum.map(fn admin ->
          ExGram.send_message(admin, stats_message, parse_mode: "Markdown")
        end)

        {:noreply, Map.put(state, :stats, stats)}

      stats ->
        %{users: users, groups: groups} = new_stats = SpotifyUriBot.Stats.get_stats()

        cond do
          Enum.count(users) == Enum.count(stats[:users]) &&
              Enum.count(groups) == Enum.count(stats[:groups]) ->
            {:noreply, stats}

          true ->
            stats_message = SpotifyUriBot.Bot.generate_stats_message(new_stats)

            # Notify admins
            ExGram.Config.get(:spotify_uri_bot, :admins, [])
            |> Enum.map(fn admin ->
              ExGram.send_message(admin, stats_message, parse_mode: "Markdown")
            end)

            {:noreply, Map.put(state, :stats, new_stats)}
        end
    end
  end
end
