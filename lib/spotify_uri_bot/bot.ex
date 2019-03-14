defmodule SpotifyUriBot.Bot do
  @bot :spotify_uri_bot

  use ExGram.Bot,
    name: @bot

  require Logger

  def bot(), do: @bot

  def handle({:command, "start", _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:text, text, %{message_id: message_id}}, context) do
    case SpotifyUriBot.Utils.parse_text(text) do
      {:ok, :track, uri} ->
        {:ok, track} = SpotifyUriBot.Server.get_track(uri)

        message = """
        🎤 Artist: `#{track[:artist]}`
        🎵 Song: `#{track[:song]}`
        📀 Album: `#{track[:album]}`
        🔗 URI: `#{track[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(track[:href])

        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup
        )

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)

        message = """
        🎤 Artist: `#{album[:artist]}`
        📀 Album: `#{album[:name]}`
        📅 Release date: `#{album[:release_date]}`
        🔗 URI: `#{album[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(album[:href])

        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup
        )

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)

        message = """
        🎤 Artist: `#{artist[:name]}`
        🔗 URI: `#{artist[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(artist[:href])

        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup
        )

      {:ok, :playlist, uri} ->
        {:ok, playlist} = SpotifyUriBot.Server.get_playlist(uri)

        description =
          case playlist[:description] do
            d when d in ["", nil] -> ""
            d -> "Description: `#{d}`"
          end

        message = """
        📄 Name: `#{playlist[:name]}`
        👤 Owner: `#{playlist[:owner]}`
        🔗 URI: `#{playlist[:uri]}`
        #{description}
        """

        markup = SpotifyUriBot.Utils.generate_url_button(playlist[:href])

        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup
        )

      {:error, message} ->
        Logger.debug(message)

      unknown ->
        Logger.debug("Unknown text: #{inspect(unknown)}")
    end
  end
end
