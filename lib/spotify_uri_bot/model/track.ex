defmodule SpotifyUriBot.Model.Track do
  defstruct [
    :artist,
    :artist_id,
    :album,
    :album_type,
    :images,
    :name,
    :href,
    :uri,
    :preview_url,
    genres: []
  ]

  require Logger

  defp multiple_artists(artist, other_artists) do
    Enum.join([artist | Enum.map(other_artists, fn artist -> artist["name"] end)], ", ")
  end

  def from_api(%{
        "artists" => [%{"name" => artist, "id" => artist_id} | other_artists],
        "album" => %{"name" => album_name, "images" => images, "album_type" => album_type},
        "name" => song_name,
        "external_urls" => %{"spotify" => href},
        "uri" => uri,
        "preview_url" => preview_url
      }) do
    track = %__MODULE__{
      artist: multiple_artists(artist, other_artists),
      artist_id: artist_id,
      album: album_name,
      album_type: album_type,
      images: images,
      name: song_name,
      href: href,
      uri: uri,
      preview_url: preview_url
    }

    {:ok, track}
  end

  def from_api(error) do
    Logger.error("Could not parse track: #{inspect(error)}")
    {:error, "Could not parse track"}
  end

  def from_top_tracks(%{
        "tracks" => tracks
      }) do
    Enum.map(tracks, fn track ->
      case track do
        %{
          "artists" => [%{"name" => artist, "id" => artist_id} | other_artists],
          "name" => song_name,
          "external_urls" => %{"spotify" => href},
          "uri" => uri,
          "preview_url" => preview_url,
          "album" => %{"name" => album_name}
        } ->
          %__MODULE__{
            artist: multiple_artists(artist, other_artists),
            artist_id: artist_id,
            name: song_name,
            href: href,
            album: album_name,
            uri: uri,
            preview_url: preview_url
          }

        _ ->
          %__MODULE__{}
      end
    end)
  end

  def from_album(
        %{
          "artists" => [%{"name" => artist, "id" => artist_id} | other_artists],
          "name" => song_name,
          "external_urls" => %{"spotify" => href},
          "uri" => uri,
          "preview_url" => preview_url
        },
        album
      ) do
    %__MODULE__{
      artist: multiple_artists(artist, other_artists),
      artist_id: artist_id,
      name: song_name,
      href: href,
      album: album.name,
      uri: uri,
      preview_url: preview_url
    }
  end

  def add_genres(track, genres) do
    %{track | genres: genres}
  end
end
