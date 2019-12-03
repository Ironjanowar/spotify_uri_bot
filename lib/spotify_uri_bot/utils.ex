defmodule SpotifyUriBot.Utils do
  import NimbleParsec

  alias ExGram.Model.InlineQueryResultAudio
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  require Logger

  uri_parse =
    ignore(string("spotify:"))
    |> choice([
      string("track"),
      string("album"),
      string("artist"),
      string("playlist"),
      ignore(string("user:"))
      |> ignore(ascii_string([?a..?z, ?A..?Z, ?0..?9, ?., ?-, ?_], min: 1))
      |> ignore(string(":"))
      |> string("playlist"),
      string("show"),
      string("episode")
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
      |> string("playlist"),
      string("show"),
      string("episode")
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
    message_format =
      """
      🎤 Artist: `#{track.artist}`
      🎵 Song: `#{track.name}`
      📀 Album: `#{track.album}`
      🔗 URI: `#{track.uri}`
      """ <> SpotifyUriBot.Utils.hashtags(track.genres)

    markup = SpotifyUriBot.Utils.generate_url_button(track.href)

    %InlineQueryResultArticle{
      type: "article",
      id: track.uri,
      title: track.name,
      input_message_content: %InputTextMessageContent{
        message_text: message_format,
        parse_mode: "Markdown"
      },
      reply_markup: markup,
      description: track.artist
    }
  end

  def search_result_to_result_audio(track) do
    message_format =
      """
      🎤 Artist: `#{track.artist}`
      🎵 Song: `#{track.name}`
      📀 Album: `#{track.album}`
      🔗 URI: `#{track.uri}`
      """ <> SpotifyUriBot.Utils.hashtags(track.genres)

    markup =
      case track.preview_url do
        nil -> SpotifyUriBot.Utils.generate_url_button(track.href)
        _ -> SpotifyUriBot.Utils.generate_url_buttons(track.href, track.uri)
      end

    %InlineQueryResultAudio{
      type: "audio",
      id: track.uri,
      title: track.name,
      performer: track.artist,
      audio_url: track.preview_url,
      input_message_content: %InputTextMessageContent{
        message_text: message_format,
        parse_mode: "Markdown"
      },
      reply_markup: markup
    }
  end

  def extract_tracks_info(track) do
    [artist | _] = track["artists"]

    %{
      name: track["name"],
      album: track["album"]["name"],
      artist: artist["name"],
      href: track["external_urls"]["spotify"],
      uri: track["uri"],
      preview_url: track["preview_url"]
    }
  end

  def hashtags([]), do: ""

  def hashtags(genres) do
    "🎸 Genres: " <>
      (Enum.map(genres, fn genre ->
         "#" <> (genre |> String.replace(~r/-| /, ""))
       end)
       |> Enum.join(" "))
  end

  def get_search_type(search_query) do
    [potential_type | query] =
      search_query
      |> String.split(" ", trim: true)

    case potential_type do
      "!" <> type -> {String.to_atom(type), Enum.join(query, " ")}
      _ -> {:track, search_query}
    end
  end

  def retry_n(n, args, callback, time \\ 500)

  def retry_n(n, args, callback, time) when n <= 0 do
    Process.sleep(time)
    apply(callback, args)
  end

  def retry_n(n, args, callback, time) do
    Process.sleep(time)

    case apply(callback, args) do
      {:error, _} ->
        Logger.error("Retrying...")
        retry_n(n - 1, {callback, args}, time)

      result ->
        result
    end
  end
end
