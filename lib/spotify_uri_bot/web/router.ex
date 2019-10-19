defmodule SpotifyUriBot.Web.Router do
  @moduledoc false

  use Plug.Router

  plug(Plug.Logger, log: :info)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/status" do
    conn |> json(%{status: "ok"})
  end

  match _ do
    conn |> json(%{ok: false}, 404)
  end

  defp json(conn, body, code \\ 200) do
    conn |> put_resp_content_type("application/json") |> send_resp(code, Jason.encode!(body))
  end
end
