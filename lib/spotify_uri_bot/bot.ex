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
    case generate_message(text) do
      :no_message ->
        :ok

      {message, :no_markup} ->
        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id
        )

      {message, markup} ->
        answer(context, message,
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: markup
        )
    end
  end

  # Private
  defp generate_message(text) do
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
        {message, markup}

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)

        message = """
        🎤 Artist: `#{album[:artist]}`
        📀 Album: `#{album[:name]}`
        📅 Release date: `#{album[:release_date]}`
        🔗 URI: `#{album[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(album[:href])
        {message, markup}

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)

        message = """
        🎤 Artist: `#{artist[:name]}`
        🔗 URI: `#{artist[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(artist[:href])

        {message, markup}

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
        {message, markup}

      {:error, message} ->
        Logger.debug(message)
        :no_message

      unknown ->
        Logger.debug("Unknown text: #{inspect(unknown)}")
        :no_message
    end
  end
end
