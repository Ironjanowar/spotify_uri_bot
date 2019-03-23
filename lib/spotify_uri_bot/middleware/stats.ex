defmodule SpotifyUriBot.Middleware.Stats do
  use ExGram.Middleware
  require Logger
  alias ExGram.Cnt
  import ExGram.Dsl

  def call(%Cnt{update: update} = cnt, _opts) do
    user = extract_user(update)
    group = extract_group(update)
    save(user, group)

    cnt
  end

  def call(cnt, _), do: cnt

  defp save({:ok, %{id: id}}, :error), do: SpotifyUriBot.Stats.add_user(id)
  defp save({:ok, %{id: id}}, {:ok, %{id: id}}), do: SpotifyUriBot.Stats.add_user(id)
  defp save(_, {:ok, %{id: cid}}), do: SpotifyUriBot.Stats.add_group(cid)
end
