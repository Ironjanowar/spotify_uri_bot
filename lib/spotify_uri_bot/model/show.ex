defmodule SpotifyUriBot.Model.Show do
  defstruct [:name, :publisher, :description, :href, :uri, :languages, :episodes]

  require Logger

  def from_api(%{
        "name" => name,
        "publisher" => publisher,
        "description" => description,
        "external_urls" => %{"spotify" => href},
        "uri" => uri,
        "languages" => languages,
        "episodes" => %{"total" => episodes}
      }) do
    show = %__MODULE__{
      name: name,
      publisher: publisher,
      description: description,
      href: href,
      uri: uri,
      languages: languages,
      episodes: episodes
    }

    {:ok, show}
  end

  def from_api(error) do
    Logger.error("Could not parse show #{inspect(error)}")
    {:error, "Could not parse show"}
  end
end
