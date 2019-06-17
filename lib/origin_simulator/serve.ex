defmodule OriginSimulator.Serve do
  import Plug.Conn
  alias OriginSimulator.{Payload,Simulation}

  def init(opts), do: opts

  def call(conn, _opts) do
    {status, latency} = Simulation.state(:simulation)

    sleep(latency)

    {:ok, body} = get_response_body(conn, status)

    conn
    |> put_resp_content_type(content_type(body))
    |> send_resp(status, body)
  end

  defp content_type(body) do
    case String.first(body) do
      "{" -> "application/json"
      "<?xml" -> "text/xml"
      _ -> "text/html"
    end
  end

  defp get_response_body(conn, status) do
    with {:ok, body} <- Payload.body(:payload, {conn.request_path, status}) do
      {:ok, body}
    else
      _ -> Payload.body(:payload, {:default, status})
    end
  end

  defp sleep(0), do: nil
  defp sleep(%Range{} = time), do: :timer.sleep(Enum.random(time))
  defp sleep(duration), do: :timer.sleep(duration)
end
