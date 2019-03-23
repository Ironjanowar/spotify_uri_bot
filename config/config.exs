# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_gram,
  token: {:system, "BOT_TOKEN"}

config :spotify_uri_bot,
  client_token: {:system, "CLIENT_TOKEN"},
  admins: []
