defmodule SpotifyUriBot.Bot do
  @bot :spotify_uri_bot

  use ExGram.Bot,
    name: @bot

  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  require Logger

  def bot(), do: @bot

  def handle({:command, "start", _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:inline_query, %{query: ""}}, _context), do: :ok

  def handle({:inline_query, %{query: text}}, context) do
    case generate_inline_options(text) do
      {:ok, articles} -> answer_inline_query(context, articles)
      _ -> Logger.debug("Ignoring query #{text}")
    end
  end

  def handle({:text, text, %{message_id: message_id}}, context) do
    case generate_message(text) do
      :no_message ->
        :ok

      {:ok, result} ->
        answer(context, result[:message],
          parse_mode: "Markdown",
          reply_to_message_id: message_id,
          reply_markup: result[:markup] || ""
        )
    end
  end

  # Private
  defp generate_inline_options(text) do
    case generate_message(text) do
      {:ok, result} ->
        {:ok,
         [
           %InlineQueryResultArticle{
             type: "article",
             id: result[:info][:uri],
             title: "Share" <> (" #{result[:entity]}" || ""),
             input_message_content: %InputTextMessageContent{
               message_text: result[:message],
               parse_mode: "Markdown"
             },
             reply_markup: result[:markup],
             description: result[:info][:name] || ""
           }
         ]}

      _ ->
        :ignore
    end
  end

  defp generate_message(text) do
    case SpotifyUriBot.Utils.parse_text(text) do
      {:ok, :track, uri} ->
        {:ok, track} = SpotifyUriBot.Server.get_track(uri)

        message = """
        🎤 Artist: `#{track[:artist]}`
        🎵 Song: `#{track[:name]}`
        📀 Album: `#{track[:album]}`
        🔗 URI: `#{track[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(track[:href])
        {:ok, message: message, markup: markup, info: track, entity: "Track"}

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)

        message = """
        🎤 Artist: `#{album[:artist]}`
        📀 Album: `#{album[:name]}`
        📅 Release date: `#{album[:release_date]}`
        🔗 URI: `#{album[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(album[:href])
        {:ok, message: message, markup: markup, info: album, entity: "Album"}

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)

        message = """
        🎤 Artist: `#{artist[:name]}`
        🔗 URI: `#{artist[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(artist[:href])

        {:ok, message: message, markup: markup, info: artist, entity: "Artist"}

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
        {:ok, message: message, markup: markup, info: playlist, entity: "Playlist"}

      {:error, message} ->
        Logger.debug(message)
        :no_message

      unknown ->
        Logger.debug("Unknown text: #{inspect(unknown)}")
        :no_message
    end
  end
end
