defmodule SpotifyUriBot.Api do
  use Tesla

  plug(Tesla.Middleware.FormUrlencoded)

  require Logger

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

    with {:ok, %{body: body}} <-
           client_token |> client() |> post("/api/token", %{grant_type: "client_credentials"}),
         {:ok, %{"access_token" => token}} <- Jason.decode(body) do
      Logger.debug("Spotify token gathered.")
      {:ok, token}
    else
      err ->
        Logger.error("Get token failed with error: #{inspect(err)}")
        get_token()
    end
  end

  def get_track(track_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/tracks/#{track_id}"),
         {:ok,
          %{
            "artists" => [%{"name" => artist, "id" => artist_id} | _],
            "album" => %{"name" => album_name},
            "name" => song_name,
            "external_urls" => %{"spotify" => href},
            "uri" => uri,
            "preview_url" => preview_url
          }} <- Jason.decode(body) do
      {:ok, %{genres: genres}} = get_artist(artist_id, token)

      {:ok,
       %{
         artist: artist,
         album: album_name,
         name: song_name,
         href: href,
         uri: uri,
         preview_url: preview_url,
         genres: genres
       }}
    else
      err ->
        Logger.error("Get track failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_track(track_id, token)
    end
  end

  def get_album(album_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/albums/#{album_id}"),
         {:ok,
          %{
            "name" => album_name,
            "artists" => [%{"name" => artist} | _],
            "release_date" => release_date,
            "external_urls" => %{"spotify" => href},
            "uri" => uri,
            "tracks" => %{"items" => tracks},
            "genres" => genres
          }} <- Jason.decode(body) do
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
    else
      err ->
        Logger.error("Get album failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_album(album_id, token)
    end
  end

  def get_artist(artist_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/artists/#{artist_id}"),
         {:ok,
          %{
            "name" => name,
            "external_urls" => %{"spotify" => href},
            "uri" => uri,
            "genres" => genres
          }} <-
           Jason.decode(body) do
      {:ok, %{name: name, href: href, uri: uri, genres: genres}}
    else
      err ->
        Logger.error("Get artist failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_artist(artist_id, token)
    end
  end

  def get_artist_top_tracks(artist_id, token) do
    with {:ok, %{body: body}} <-
           token
           |> authorized_client()
           |> get("/artists/#{artist_id}/top-tracks", query: [country: "ES"]),
         {:ok, %{"tracks" => tracks}} <- Jason.decode(body) do
      tracks = Enum.map(tracks, &SpotifyUriBot.Utils.extract_tracks_info/1)

      {:ok, tracks}
    else
      err ->
        Logger.error("Get artist top tracks failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_artist_top_tracks(artist_id, token)
    end
  end

  def get_playlist(playlist_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/playlists/#{playlist_id}"),
         {:ok,
          %{
            "name" => name,
            "owner" => %{"display_name" => owner},
            "description" => description,
            "external_urls" => %{"spotify" => href},
            "uri" => uri
          }} <- Jason.decode(body) do
      {:ok, %{name: name, owner: owner, description: description, href: href, uri: uri}}
    else
      err ->
        Logger.error("Get playlist failed with error: #{inspect(err)}")
    end
  end

  def get_show(show_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/shows/#{show_id}"),
         {:ok,
          %{
            "name" => name,
            "publisher" => publisher,
            "description" => description,
            "external_urls" => %{"spotify" => href},
            "uri" => uri,
            "languages" => languages,
            "episodes" => %{"total" => episodes}
          }} <- Jason.decode(body) do
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
    else
      err ->
        Logger.error("Get show failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_show(show_id, token)
    end
  end

  def get_episode(episode_id, token) do
    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/episodes/#{episode_id}"),
         {:ok,
          %{
            "name" => name,
            "show" => %{"name" => show, "publisher" => publisher},
            "description" => description,
            "language" => language,
            "uri" => uri,
            "audio_preview_url" => preview_url,
            "external_urls" => %{"spotify" => href}
          }} <- Jason.decode(body) do
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
    else
      err ->
        Logger.error("Get episode failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        get_episode(episode_id, token)
    end
  end

  def search(query, types, token) do
    types = Enum.join(types, ",")
    params = [q: URI.encode(query), type: types, limit: 5]

    with {:ok, %{body: body}} <- token |> authorized_client() |> get("/search", query: params),
         {:ok, search_result} <- Jason.decode(body) do
      {:ok, search_result}
    else
      err ->
        Logger.error("Search failed with error: #{inspect(err)}")
        Logger.error("Retrying...")
        search(query, types, token)
    end
  end
end
