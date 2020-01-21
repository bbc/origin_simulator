defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload, Recipe, Simulation, PlugResponseCounter, Counter}
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
    Simulation.restart()
    Process.sleep(10)

    recipe = Recipe.parse(Plug.Conn.read_body(conn))
    Simulation.add_recipe(:simulation, recipe)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Poison.encode!(Simulation.recipe(:simulation)))
  end

  get "/*glob" do
    recipe_route = Simulation.route(:simulation)
    serve_payload?(conn, recipe_route, conn.request_path)
  end

  post "/*glob" do
    serve_payload(conn)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp serve_payload?(conn, nil, _), do: serve_payload(conn)
  defp serve_payload?(conn, route, req_path) when route == req_path, do: serve_payload(conn, route)

  defp serve_payload?(conn, _, req_path) do
    msg = "Recipe not set at #{req_path}, please POST a recipe for this route to /add_recipe"
    conn |> send_resp(406, msg)
  end

  defp serve_payload(conn, route \\ nil) do
    {status, latency} = Simulation.state(:simulation)

    sleep(latency)

    {:ok, body} = Payload.body(:payload, status, route)

    recipe = Simulation.recipe(:simulation)

    conn
    |> put_resp_content_type(content_type(body))
    |> merge_resp_headers(recipe_headers(recipe))
    |> send_resp(status, body)
  end

  defp recipe_headers(nil), do: []
  defp recipe_headers(recipe), do: recipe.headers

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
