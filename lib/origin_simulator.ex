defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.Simulation
  alias OriginSimulator.Payload

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

  post "/add_recipe" do
    restart_server()

    recipe = parse_body(conn)
    Simulation.add_recipe(:simulation, recipe)
    Payload.fetch(:payload, recipe["origin"])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Poison.encode!(Simulation.recipe(:simulation)))
  end

  get "/" do
    {status, latency} = Simulation.state(:simulation)

    if latency > 0 do
      :timer.sleep(latency)
    end

    {:ok, body} = Payload.body(:payload, status)
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, body)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  @spec parse_body(%Plug.Conn{}) :: String.t()
  defp parse_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    Poison.decode!(body)
  end

  defp restart_server() do
    server_pid = GenServer.whereis(:simulation)

    if server_pid do
      Process.exit(server_pid, :kill)
      :timer.sleep(50) #just the time to restart the Simulation server
    end
  end
end
