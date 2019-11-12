defmodule SpotifyUriBot.Model.Playlist do
  defstruct [:name, :owner, :description, :href, :uri]

  def from_api(%{
        "name" => name,
        "owner" => %{"display_name" => owner},
        "description" => description,
        "external_urls" => %{"spotify" => href},
        "uri" => uri
      }) do
    playlist = %__MODULE__{
      name: name,
      owner: owner,
      description: description,
      href: href,
      uri: uri
    }

    {:ok, playlist}
  end

  def from_api(_), do: :error
end
