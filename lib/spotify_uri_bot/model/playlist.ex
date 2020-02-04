defmodule SpotifyUriBot.Model.Playlist do
  defstruct [:name, :owner, :description, :href, :uri]

  require Logger

  def from_api(
        %{
          "name" => name,
          "owner" => %{"display_name" => owner},
          "external_urls" => %{"spotify" => href},
          "uri" => uri
        } = raw_playlist
      ) do
    playlist = %__MODULE__{
      name: name,
      owner: owner,
      description: raw_playlist["description"] || "",
      href: href,
      uri: uri
    }

    {:ok, playlist}
  end

  def from_api(error) do
    Logger.error("Could not parse playlist: #{inspect(error)}")
    {:error, "Could not parse playlist"}
  end
end
