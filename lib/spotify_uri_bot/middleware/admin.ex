defmodule SpotifyUriBot.Middleware.Admin do
  use ExGram.Middleware
  require Logger
  alias ExGram.Cnt
  import ExGram.Dsl

  @admins ExGram.Config.get(:spotify_uri_bot, :admins, [])

  def call(%Cnt{update: update} = cnt, _opts) do
    {:ok, %{id: id}} = extract_user(update)

    case id in @admins do
      true -> add_extra(cnt, :is_admin, true)
      _ -> add_extra(cnt, :is_admin, false)
    end
  end

  def call(cnt, _), do: cnt
end
