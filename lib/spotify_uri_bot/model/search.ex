defmodule SpotifyUriBot.Model.Search do
  alias SpotifyUriBot.Model.{Track, Artist, Album, Playlist, Show, Episode}

  require Logger

  defp add_title_and_description(%Track{} = track) do
    Map.merge(track, %{title: track.name, description: track.artist})
  end

  defp add_title_and_description(%Artist{} = artist) do
    Map.merge(artist, %{title: artist.name, description: ""})
  end

  defp add_title_and_description(%Album{} = album) do
    Map.merge(album, %{title: album.name, description: album.artist})
  end

  defp add_title_and_description(%Playlist{} = playlist) do
    Map.merge(playlist, %{title: playlist.name, description: playlist.owner})
  end

  defp add_title_and_description(%Show{} = show) do
    Map.merge(show, %{title: show.name, description: show.publisher})
  end

  defp add_title_and_description(%Episode{} = episode) do
    Map.merge(episode, %{title: episode.name, description: episode.publisher})
  end

  defp add_title_and_description(unknown), do: unknown

  def from_api(%{"tracks" => %{"items" => items}}) do
    tracks =
      Enum.map(items, fn track ->
        track |> Track.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:tracks, tracks}}
  end

  def from_api(%{"artists" => %{"items" => items}}) do
    artists =
      Enum.map(items, fn artist ->
        artist |> Artist.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:artists, artists}}
  end

  def from_api(%{"albums" => %{"items" => items}}) do
    albums =
      Enum.map(items, fn album ->
        album |> Album.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:albums, albums}}
  end

  def from_api(%{"playlists" => %{"items" => items}}) do
    playlists =
      Enum.map(items, fn playlist ->
        playlist |> Playlist.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:playlists, playlists}}
  end

  def from_api(%{"shows" => %{"items" => items}}) do
    shows =
      Enum.map(items, fn show ->
        show |> Show.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:shows, shows}}
  end

  def from_api(%{"episodes" => %{"items" => items}}) do
    episodes =
      Enum.map(items, fn episode ->
        episode |> Episode.from_api() |> elem(1) |> add_title_and_description()
      end)

    {:ok, {:episodes, episodes}}
  end

  def from_api(error) do
    Logger.error("Could not parse search result: #{inspect(error)}")
    {:error, "Could not parse search result"}
  end
end
