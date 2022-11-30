# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

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
  backends: [{LoggerFileBackend, :debug}, {LoggerFileBackend, :error}]

config :logger, :debug,
  path: "log/debug.log",
  level: :debug,
  format: "$dateT$timeZ [$level] $message\n"

config :logger, :error,
  path: "log/error.log",
  level: :error,
  format: "$dateT$timeZ [$level] $message\n"
