defmodule SpotifyUriBot.Web do
  @moduledoc false

  alias __MODULE__.Router

  require Logger

  def child_spec(_opts) do
    port = ExGram.Config.get(:spotify_uri_bot, :port, "4000") |> String.to_integer()
    ranch_opts = [port: port, ref: SpotifyUriBot.Web]
    cowboy_opts = [scheme: :http, plug: Router, options: ranch_opts]

    Logger.info("Running #{inspect(__MODULE__)} with Cowboy using: http://0.0.0.0:#{port}")
    Plug.Cowboy.child_spec(cowboy_opts)
  end
end
