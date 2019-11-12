defmodule SpotifyUriBot.Model.Search do
  alias SpotifyUriBot.Model.{Track, Artist, Album, Playlist, Show, Episode}

  def from_api(%{"tracks" => %{"items" => items}}) do
    tracks = Enum.map(items, fn track -> track |> Track.from_api() |> elem(1) end)
    {:ok, {:tracks, tracks}}
  end

  def from_api(%{"artists" => %{"items" => items}}) do
    artists = Enum.map(items, fn artist -> artist |> Artist.from_api() |> elem(1) end)
    {:ok, {:artists, artists}}
  end

  def from_api(%{"albums" => %{"items" => items}}) do
    albums = Enum.map(items, fn album -> album |> Album.from_api() |> elem(1) end)
    {:ok, {:albums, albums}}
  end

  def from_api(%{"playlists" => %{"items" => items}}) do
    playlists = Enum.map(items, fn playlist -> playlist |> Playlist.from_api() |> elem(1) end)
    {:ok, {:playlists, playlists}}
  end

  def from_api(%{"shows" => %{"items" => items}}) do
    shows = Enum.map(items, fn show -> show |> Show.from_api() |> elem(1) end)
    {:ok, {:shows, shows}}
  end

  def from_api(%{"episodes" => %{"items" => items}}) do
    episodes = Enum.map(items, fn episode -> episode |> Episode.from_api() |> elem(1) end)
    {:ok, {:episodes, episodes}}
  end

  def from_api(_), do: :error
end
