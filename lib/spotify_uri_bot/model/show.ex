defmodule SpotifyUriBot.Model.Show do
  defstruct [:name, :publisher, :description, :href, :uri, :languages, :episodes]

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

  def from_api(_), do: :error
end
