defmodule SpotifyUriBot.Bot do
  @bot :spotify_uri_bot

  use ExGram.Bot,
    name: @bot

  require Logger

  def bot(), do: @bot

  def handle({:command, "start", _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:text, text, _msg}, context) do
    case SpotifyUriBot.Utils.parse_text(text) do
      {:ok, uri} ->
        {:ok, track} = SpotifyUriBot.Server.get_track(uri)

        message =
          "🎤 `Artist:` #{track[:artist]}\n🎵 `  Song:` #{track[:song]}\n📀 ` Album:` #{
            track[:album]
          }"

        answer(context, message, parse_mode: "Markdown")

      {:error, message} ->
        Logger.debug(message)
    end
  end
end
