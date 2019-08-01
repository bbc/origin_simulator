defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload,Recipe,Simulation,RoutingTable,PlugResponseCounter,Counter}
  plug(PlugResponseCounter)

  plug(:match)
  plug(:dispatch)

  get "/status" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/current_recipe" do
    msg = Simulation.recipe(:simulation) || "Not set, please POST a recipe to /add_recipe"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(msg))
  end

  get "/clear_current_count" do
    Counter.clear()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"cleared": "yes"}))
  end

  get "/current_count" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(Counter.value()))
  end

  post "/add_recipe" do
    Simulation.stop
    Payload.stop(:payloads)
    Process.sleep(10)

    recipe = Recipe.parse(Plug.Conn.read_body(conn))
    Simulation.add_recipe(:simulation, recipe)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Poison.encode!(Simulation.recipe(:simulation)))
  end

  match _, via: [:post, :get] do
    create_response(conn.request_path)
    |> serve_payload(conn)
  end

  defp create_response(request_path) do
    with {:ok, pattern} <- RoutingTable.find_route(:routing_table, request_path),
         {:ok, status, latency} <- Simulation.state(:simulation, pattern),
         {:ok, body} <- Payload.body(:payloads, status, pattern)
      do %{status: status, body: body, latency: latency} end
      |> case do
           {:error, message} -> %{status: 500, body: message, latency: 0}
           response -> response
         end
  end

  defp serve_payload(%{status: status, body: body, latency: latency}, conn) do
    sleep(latency)
    conn
    |> put_resp_content_type(content_type(body))
    |> send_resp(status, body)
  end

  defp content_type(body) do
    if String.first(body) == "{" do
      "application/json"
    else
      "text/html"
    end
  end

  defp sleep(0), do: nil
  defp sleep(%Range{} = time), do: :timer.sleep(Enum.random(time))
  defp sleep(duration), do: :timer.sleep(duration)
end
