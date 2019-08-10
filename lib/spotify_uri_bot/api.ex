defmodule SpotifyUriBot.Api do
  use Tesla

  plug(Tesla.Middleware.FormUrlencoded)

  def client(client_token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, "https://accounts.spotify.com"},
      {Tesla.Middleware.Headers, [{"Authorization", "Basic #{client_token}"}]}
    ]

    Tesla.client(middlewares)
  end

  def authorized_client(token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]}
    ]

    Tesla.client(middlewares)
  end

  def get_token() do
    client_token = ExGram.Config.get(:spotify_uri_bot, :client_token)

    {:ok, %{body: body}} =
      client_token |> client() |> post("/api/token", %{grant_type: "client_credentials"})

    %{"access_token" => token} = Jason.decode!(body)
    {:ok, token}
  end

  def get_track(track_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/tracks/#{track_id}")

    %{
      "artists" => [%{"name" => artist} | _],
      "album" => %{"name" => album_name},
      "name" => song_name,
      "external_urls" => %{"spotify" => href},
      "uri" => uri,
      "preview_url" => preview_url
    } = Jason.decode!(body)

    {:ok,
     %{
       artist: artist,
       album: album_name,
       name: song_name,
       href: href,
       uri: uri,
       preview_url: preview_url
     }}
  end

  def get_album(album_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/albums/#{album_id}")

    %{
      "name" => album_name,
      "artists" => [%{"name" => artist} | _],
      "release_date" => release_date,
      "external_urls" => %{"spotify" => href},
      "uri" => uri,
      "tracks" => %{"items" => tracks},
      "genres" => genres
    } = Jason.decode!(body)

    tracks = Enum.map(tracks, &SpotifyUriBot.Utils.extract_tracks_info/1)

    {:ok,
     %{
       artist: artist,
       name: album_name,
       release_date: release_date,
       href: href,
       uri: uri,
       tracks: tracks,
       genres: genres
     }}
  end

  def get_artist(artist_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/artists/#{artist_id}")

    %{"name" => name, "external_urls" => %{"spotify" => href}, "uri" => uri, "genres" => genres} =
      Jason.decode!(body)

    {:ok, %{name: name, href: href, uri: uri, genres: genres}}
  end

  def get_artist_top_tracks(artist_id, token) do
    {:ok, %{body: body}} =
      token
      |> authorized_client()
      |> get("/artists/#{artist_id}/top-tracks", query: [country: "ES"])

    %{"tracks" => tracks} = Jason.decode!(body)

    tracks = Enum.map(tracks, &SpotifyUriBot.Utils.extract_tracks_info/1)

    {:ok, tracks}
  end

  def get_playlist(playlist_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/playlists/#{playlist_id}")

    %{
      "name" => name,
      "owner" => %{"display_name" => owner},
      "description" => description,
      "external_urls" => %{"spotify" => href},
      "uri" => uri
    } = Jason.decode!(body)

    {:ok, %{name: name, owner: owner, description: description, href: href, uri: uri}}
  end

  def get_show(show_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/shows/#{show_id}")

    %{
      "name" => name,
      "publisher" => publisher,
      "description" => description,
      "external_urls" => %{"spotify" => href},
      "uri" => uri,
      "languages" => languages,
      "episodes" => %{"total" => episodes}
    } = Jason.decode!(body)

    {:ok,
     %{
       name: name,
       publisher: publisher,
       description: description,
       href: href,
       uri: uri,
       languages: languages,
       episodes: episodes
     }}
  end

  def get_episode(episode_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/episodes/#{episode_id}")

    %{
      "name" => name,
      "show" => %{"name" => show, "publisher" => publisher},
      "description" => description,
      "language" => language,
      "uri" => uri,
      "audio_preview_url" => preview_url,
      "external_urls" => %{"spotify" => href}
    } = Jason.decode!(body)

    {:ok,
     %{
       name: name,
       publisher: publisher,
       show: show,
       description: description,
       language: language,
       uri: uri,
       preview_url: preview_url,
       href: href
     }}
  end

  def search(query, types, token) do
    types = Enum.join(types, ",")
    params = [q: URI.encode(query), type: types, limit: 5]

    token |> authorized_client() |> get("/search", query: params)
  end
end
