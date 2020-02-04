defmodule SpotifyUriBot.Model.Album do
  defstruct [:artist, :artist_id, :name, :release_date, :href, :uri, :tracks, :genres]

  require Logger

  def from_api(
        %{
          "name" => album_name,
          "artists" => [%{"name" => artist, "id" => artist_id} | _],
          "release_date" => release_date,
          "external_urls" => %{"spotify" => href},
          "uri" => uri
        } = raw_album
      ) do
    album = %__MODULE__{
      artist: artist,
      artist_id: artist_id,
      name: album_name,
      release_date: release_date,
      href: href,
      uri: uri,
      tracks: raw_album["tracks"]["items"] || [],
      genres: raw_album["genres"] || []
    }

    {:ok, album}
  end

  def from_api(error) do
    Logger.error("Could not parse album: #{inspect(error)}")
    {:error, "Could not parse album"}
  end

  def add_tracks(album, tracks_info) do
    %{album | tracks: tracks_info}
  end
end
