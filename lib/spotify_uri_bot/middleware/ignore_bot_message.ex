defmodule SpotifyUriBot.Middleware.IgnoreBotMessage do
  use ExGram.Middleware

  alias ExGram.Cnt

  def call(%Cnt{update: %{message: %{text: text}}} = cnt, _opts) do
    if String.contains?(text, "🔗 URI: ") do
      add_extra(cnt, :message_from_bot, true)
    else
      add_extra(cnt, :message_from_bot, false)
    end
  end

  def call(cnt, _), do: cnt
end
