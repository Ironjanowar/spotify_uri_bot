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
      "uri" => uri
    } = Jason.decode!(body)

    {:ok, %{artist: artist, name: album_name, release_date: release_date, href: href, uri: uri}}
  end

  def get_artist(artist_id, token) do
    {:ok, %{body: body}} = token |> authorized_client() |> get("/artists/#{artist_id}")

    %{"name" => name, "external_urls" => %{"spotify" => href}, "uri" => uri} = Jason.decode!(body)

    {:ok, %{name: name, href: href, uri: uri}}
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

  def search(query, types, token) do
    types = Enum.join(types, ",")
    params = [q: URI.encode(query), type: types, limit: 5]

    token |> authorized_client() |> get("/search", query: params)
  end
end
