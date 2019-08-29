defmodule SpotifyUriBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :spotify_uri_bot,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SpotifyUriBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_gram, "~> 0.7.1"},
      {:tesla, "~> 1.2.1"},
      {:jason, "~> 1.1"},
      {:nimble_parsec, "~> 0.2"},
      {:redix, ">= 0.0.0"},
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},
      {:logger_file_backend, "0.0.10"}
    ]
  end
end
