defmodule SpotifyUriBot.Model.Artist do
  defstruct [:name, :href, :uri, :genres]

  require Logger

  def from_api(%{
        "name" => name,
        "external_urls" => %{"spotify" => href},
        "uri" => uri,
        "genres" => genres
      }) do
    artist = %__MODULE__{name: name, href: href, uri: uri, genres: genres}

    {:ok, artist}
  end

  def from_api(artist) do
    Logger.error("Could not parse artist: #{inspect(artist)}")
    {:error, "Could not parse artist"}
  end
end
