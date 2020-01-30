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
    recipes = Simulation.recipe(:simulation)
    msg = if recipes == [], do: "Not set, please POST a recipe to /add_recipe", else: recipes

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
    response = Simulation.add_recipe(:simulation, recipe)

    {status, body, content_type} =
      case response do
        :ok -> {201, Poison.encode!(Simulation.recipe(:simulation)), "application/json"}
        :error -> {406, "Not Acceptable", "text/html"}
      end

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, body)
  end

  get "/*glob" do
    serve_payload(conn, Simulation.route(:simulation, conn.request_path))
  end

  post "/*glob" do
    serve_payload(conn, Simulation.route(:simulation, conn.request_path))
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp serve_payload(conn, route) do
    {status, latency} = Simulation.state(:simulation, route)

    sleep(latency)

    {:ok, body} = Payload.body(:payload, status, conn.request_path, route)

    recipe = Simulation.recipe(:simulation, route)

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
