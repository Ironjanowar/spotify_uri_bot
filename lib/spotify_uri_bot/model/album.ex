defmodule SpotifyUriBot.Model.Album do
  defstruct [:artist, :artist_id, :name, :release_date, :href, :uri, :tracks, :genres]

  def from_api(%{
        "name" => album_name,
        "artists" => [%{"name" => artist, "id" => artist_id} | _],
        "release_date" => release_date,
        "external_urls" => %{"spotify" => href},
        "uri" => uri,
        "tracks" => %{"items" => tracks},
        "genres" => genres
      }) do
    album = %__MODULE__{
      artist: artist,
      artist_id: artist_id,
      name: album_name,
      release_date: release_date,
      href: href,
      uri: uri,
      tracks: tracks,
      genres: genres
    }

    {:ok, album}
  end

  def from_api(_), do: :error

  def add_tracks(album, tracks_info) do
    %{album | tracks: tracks_info}
  end
end
