defmodule SpotifyUriBot.Utils do
  import NimbleParsec

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

  defparsec(:uri_parser, uri_parse)

  def spotify_uri?({:ok, [type, uri], _, _, _, _}),
    do: {:ok, String.to_atom(type), uri}

  def spotify_uri?(_), do: {:error, "Spotify URI not found in text"}

  def parse_text(text) do
    text
    |> String.split(" ", trim: true)
    |> Enum.find(fn t ->
      case uri_parser(t) do
        {:ok, _, _, _, _, _} -> true
        _ -> false
      end
    end)
    |> uri_parser()
    |> spotify_uri?()
  end

  def generate_url_button(url) do
    ExGram.Dsl.create_inline([[[text: "Open in Spotify", url: url]]])
  end
end
