defmodule SpotifyUriBot.Api do
  use Tesla

  @client_token ExGram.Config.get(:spotify_uri_bot, :client_token)

  plug(Tesla.Middleware.FormUrlencoded)

  def get_token() do
    {:ok, %{body: body}} =
      post("https://accounts.spotify.com/api/token", %{grant_type: "client_credentials"},
        headers: [
          {"Authorization", "Basic #{@client_token}"}
        ]
      )

    %{"access_token" => token} = Jason.decode!(body)
    {:ok, token}
  end

  def get_track(track_id, token) do
    {:ok, %{body: body}} =
      get("https://api.spotify.com/v1/tracks/#{track_id}",
        headers: [{"Authorization", "Bearer #{token}"}]
      )

    %{
      "artists" => [%{"name" => artist} | _],
      "album" => %{"name" => album_name},
      "name" => song_name
    } = Jason.decode!(body)

    {:ok, %{artist: artist, album: album_name, song: song_name}}
  end
end
