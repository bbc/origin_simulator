defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload,Recipe,Simulation}

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
    Simulation.restart(:simulation)
    Process.sleep(10)

    recipe = Recipe.parse(Plug.Conn.read_body(conn))
    Simulation.add_recipe(:simulation, recipe)

    Payload.fetch(:payload, recipe)

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
end
