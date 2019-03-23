defmodule SpotifyUriBot.Application do
  use Application

  require Logger

  def start(_type, _args) do
    token = ExGram.Config.get(:ex_gram, :token)

    # List all child processes to be supervised
    children = [
      ExGram,
      SpotifyUriBot.Server,
      SpotifyUriBot.Stats,
      {Redix, [host: "localhost", port: 6379, name: :redix]},
      {SpotifyUriBot.Bot, [method: :polling, token: token]}
    ]

    opts = [strategy: :one_for_one, name: SpotifyUriBot.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        Logger.info("SpotifyUriBot started")
        ok

      error ->
        Logger.error("Error starting SpotifyUriBot")
        error
    end
  end
end
