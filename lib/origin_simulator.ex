defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload, Recipe, Simulation, PlugResponseCounter, Counter}

  @default_route Recipe.default_route()

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
    response = Simulation.add_recipe(:simulation, recipe)

    {code, message, content_type} = case response do
      :ok -> {201, Poison.encode!(Simulation.recipe(:simulation)), "application/json"}
      :error -> {406, "Not Acceptable", "text/html"}
    end

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(code, message)
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

  defp serve_payload?(conn, @default_route, _), do: serve_payload(conn)
  defp serve_payload?(conn, route, path) when route == path, do: serve_payload(conn, route)

  defp serve_payload?(conn, route, path) do
    cond do
      # wildcard regex matching
      String.ends_with?(route, "*") && String.match?(path, ~r/^#{route}/) ->
        serve_payload(conn, route)
      true ->
        msg = "Recipe not set at #{path}, please POST a recipe for this route to /add_recipe"
        conn |> send_resp(406, msg)
    end
  end

  defp serve_payload(conn, route \\ @default_route) do
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
