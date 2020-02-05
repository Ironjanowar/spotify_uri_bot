defmodule SpotifyUriBot.Middleware.IgnoreBotMessage do
  use ExGram.Middleware

  alias ExGram.Cnt

  defp is_spotify_button?(%{text: "Open in Spotify"}), do: true
  defp is_spotify_button?(_), do: false

  def call(
        %Cnt{
          update: %{
            message: %{
              reply_markup: %{inline_keyboard: [[first_button | _] | _]}
            }
          }
        } = cnt,
        _opts
      ) do
    if is_spotify_button?(first_button) do
      %{cnt | halted: true}
    else
      cnt
    end
  end

  def call(cnt, _), do: cnt
end
