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
      {:ok, :track, uri} ->
        {:ok, track} = SpotifyUriBot.Server.get_track(uri)

        message = """
        🎤 Artist: `#{track[:artist]}`
        🎵 Song: `#{track[:song]}`
        📀 Album: `#{track[:album]}`
        """

        answer(context, message, parse_mode: "Markdown")

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)

        message = """
        🎤 Artist: `#{album[:artist]}`
        📀 Album: `#{album[:name]}`
        📅 Release date: `#{album[:release_date]}`
        """

        answer(context, message, parse_mode: "Markdown")

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)

        message = """
        🎤 Artist: `#{artist[:name]}`
        """

        answer(context, message, parse_mode: "Markdown")

      {:error, message} ->
        Logger.debug(message)
    end
  end
end
