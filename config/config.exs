# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_gram,
  token: {:system, "BOT_TOKEN"}

config :ex_gram, ExGram.Adapter.Tesla,
  middlewares: [
    {SpotifyUriBot.TeslaMiddlewares, :retry, []}
  ]

config :spotify_uri_bot,
  client_token: {:system, "CLIENT_TOKEN"},
  admins: [],
  port: {:system, "PORT"}

config :spotify_uri_bot, SpotifyUriBot.Scheduler,
  timezone: "Europe/Madrid",
  jobs: [
    # Runs every midnight:
    {"0 9 * * *", {SpotifyUriBot.Cron, :check_stats, []}}
  ]

config :logger,
  level: :debug,
  truncate: :infinity,
  backends: [{LoggerJSONFileBackend, :log_name}]

config :logger, :log_name,
  path: "log/debug.log",
  level: :debug,
  metadata: [:file, :line],
  json_encoder: Jason,
  uuid: true
