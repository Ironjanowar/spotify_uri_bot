defmodule SpotifyUriBot.Bot do
  @bot :spotify_uri_bot

  use ExGram.Bot,
    name: @bot

  alias ExGram.Model.InlineQueryResultAudio
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
      {:ok, %{info: %{preview_url: preview_url}} = result} when not is_nil(preview_url) ->
        Logger.debug("Generating audio")

        {:ok,
         [
           %InlineQueryResultAudio{
             type: "audio",
             id: result[:info][:uri],
             title: result[:info][:name],
             performer: result[:info][:artist],
             audio_url: result[:info][:preview_url],
             input_message_content: %InputTextMessageContent{
               message_text: result[:message],
               parse_mode: "Markdown"
             },
             reply_markup: result[:markup]
           }
         ]}

      {:ok, result} ->
        Logger.debug("Generating article: #{inspect(result)}")

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

      {:no_uri, search_query} ->
        {:ok, result} = SpotifyUriBot.Server.search(search_query)
        audios = Enum.map(result, &SpotifyUriBot.Utils.search_result_to_result_audio/1)
        {:ok, audios}

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

        markup =
          case track[:preview_url] do
            nil -> SpotifyUriBot.Utils.generate_url_button(track[:href])
            _ -> SpotifyUriBot.Utils.generate_url_buttons(track[:href], track[:uri])
          end

        {:ok, %{message: message, markup: markup, info: track, entity: "Track"}}

      {:ok, :album, uri} ->
        {:ok, album} = SpotifyUriBot.Server.get_album(uri)

        message = """
        🎤 Artist: `#{album[:artist]}`
        📀 Album: `#{album[:name]}`
        📅 Release date: `#{album[:release_date]}`
        🔗 URI: `#{album[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(album[:href])
        {:ok, %{message: message, markup: markup, info: album, entity: "Album"}}

      {:ok, :artist, uri} ->
        {:ok, artist} = SpotifyUriBot.Server.get_artist(uri)

        message = """
        🎤 Artist: `#{artist[:name]}`
        🔗 URI: `#{artist[:uri]}`
        """

        markup = SpotifyUriBot.Utils.generate_url_button(artist[:href])

        {:ok, %{message: message, markup: markup, info: artist, entity: "Artist"}}

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
        {:ok, %{message: message, markup: markup, info: playlist, entity: "Playlist"}}

      {:error, message} ->
        Logger.debug(message)
        :no_uri

      _ ->
        Logger.debug("Not URI or URL: #{text}")
        {:no_uri, text}
    end
  end
end
