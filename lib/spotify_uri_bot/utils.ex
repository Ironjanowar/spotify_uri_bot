defmodule SpotifyUriBot.Utils do
  import NimbleParsec

  alias ExGram.Model.InlineQueryResultAudio
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  uri_parse =
    ignore(string("spotify:"))
    |> choice([
      string("track"),
      string("album"),
      string("artist"),
      ignore(string("user:"))
      |> ignore(ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1))
      |> ignore(string(":"))
      |> string("playlist")
    ])
    |> ignore(string(":"))
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  url_parse =
    ignore(string("https://open.spotify.com/"))
    |> choice([
      string("track"),
      string("album"),
      string("artist"),
      ignore(string("user/"))
      |> ignore(ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1))
      |> ignore(string("/"))
      |> string("playlist")
    ])
    |> ignore(string("/"))
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  parse = choice([uri_parse, url_parse])

  defparsec(:uri_parser, parse)

  def parse_text(text) do
    text
    |> String.split(" ", trim: true)
    |> Enum.find_value(fn t ->
      case uri_parser(t) do
        {:ok, [type, uri], _, _, _, _} -> {:ok, String.to_atom(type), uri}
        _ -> nil
      end
    end)
  end

  def generate_url_button(url) do
    ExGram.Dsl.create_inline([[[text: "Open in Spotify", url: url]]])
  end

  def generate_url_buttons(url, uri) do
    ExGram.Dsl.create_inline([
      [
        [text: "Open in Spotify", url: url],
        [text: "Show preview", switch_inline_query_current_chat: uri]
      ]
    ])
  end

  def search_result_to_result_audio(%{preview_url: nil} = track) do
    message_format = """
    🎤 Artist: `#{track[:artist]}`
    🎵 Song: `#{track[:name]}`
    📀 Album: `#{track[:album]}`
    🔗 URI: `#{track[:uri]}`
    """

    markup = SpotifyUriBot.Utils.generate_url_button(track[:href])

    %InlineQueryResultArticle{
      type: "article",
      id: track[:uri],
      title: track[:name],
      input_message_content: %InputTextMessageContent{
        message_text: message_format,
        parse_mode: "Markdown"
      },
      reply_markup: markup,
      description: track[:artist]
    }
  end

  def search_result_to_result_audio(track) do
    message_format = """
    🎤 Artist: `#{track[:artist]}`
    🎵 Song: `#{track[:name]}`
    📀 Album: `#{track[:album]}`
    🔗 URI: `#{track[:uri]}`
    """

    markup = SpotifyUriBot.Utils.generate_url_button(track[:href])

    %InlineQueryResultAudio{
      type: "audio",
      id: track[:uri],
      title: track[:name],
      performer: track[:artist],
      audio_url: track[:preview_url],
      input_message_content: %InputTextMessageContent{
        message_text: message_format,
        parse_mode: "Markdown"
      },
      reply_markup: markup
    }
  end
end
