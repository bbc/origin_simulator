defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload, Recipe, Simulation, PlugResponseCounter, Counter}

  plug(PlugResponseCounter)
  plug(:match)
  plug(:dispatch)

  get "/:admin/status" do
    case admin_path?(conn.path_params) do
      true ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "ok!")

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/current_recipe" do
    case admin_path?(conn.path_params) do
      true ->
        recipes = Simulation.recipe(:simulation)
        msg = if recipes == [], do: recipe_not_set(), else: recipes

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(msg))

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/clear_current_count" do
    case admin_path?(conn.path_params) do
      true ->
        Counter.clear()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, ~s({"cleared": "yes"}))

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/current_count" do
    case admin_path?(conn.path_params) do
      true ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(Counter.value()))

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  post "/:admin/add_recipe" do
    case admin_path?(conn.path_params) do
      true ->
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

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/restart" do
    case admin_path?(conn.path_params) do
      true ->
        Simulation.restart()
        Process.sleep(10)

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "ok!")

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/routes" do
    case admin_path?(conn.path_params) do
      true ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, Simulation.route(:simulation) |> Enum.join("\n"))

      _ ->
        recipe_not_set_resp(conn)
    end
  end

  get "/:admin/routes_status" do
    case admin_path?(conn.path_params) do
      true ->
        body =
          for {route, simulation} <- Simulation.state(:simulation) do
            "#{route} #{simulation.status} #{simulation.latency}"
          end
          |> Enum.join("\n")

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, body)

      _ ->
        recipe_not_set_resp(conn)
    end
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

  def admin_domain(), do: Application.get_env(:origin_simulator, :admin_domain)

  defp admin_path?(%{"admin" => admin}), do: admin == admin_domain()

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

  defp recipe_not_set_resp(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, recipe_not_set(conn.request_path))
  end

  def recipe_not_set(),
    do: "Recipe not set, please POST a recipe to /#{admin_domain()}/add_recipe"

  def recipe_not_set(path) do
    "Recipe not set at #{path}, please POST a recipe for this route to /#{admin_domain()}/add_recipe"
  end
end
