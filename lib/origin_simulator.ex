defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload, Recipe, Simulation, PlugResponseCounter, Counter}

  plug(PlugResponseCounter)
  plug(:match)
  plug(:dispatch)

  @admin_domain Application.get_env(:origin_simulator, :admin_domain)

  get "/:admin/status" when admin == @admin_domain do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/:admin/current_recipe" when admin == @admin_domain do
    recipes = Simulation.recipe(:simulation)
    msg = if recipes == [], do: recipe_not_set(), else: recipes

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(msg))
  end

  get "/:admin/clear_current_count" when admin == @admin_domain do
    Counter.clear()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"cleared": "yes"}))
  end

  # TODO: consider ways to bifurcate counts per route, using
  # OTP state to store count rather than a Plug 
  get "/:admin/current_count" when admin == @admin_domain do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(Counter.value()))
  end

  post "/:admin/add_recipe" when admin == @admin_domain do
    # TODO: tofix, origin_simulator currently not handling malformed recipe
    # as `Recipe.parse` hard-wired to output from
    # Plug read i.e. {:ok, binary, any} with `Poison.decode!`
    # that throws uncaught `Poison.ParseError` exception 
    recipe = Recipe.parse(Plug.Conn.read_body(conn))
    response = Simulation.add_recipe(:simulation, recipe)

    # TODO: Simulation.recipe no longer return :error
    {status, body, content_type} =
      case response do
        :ok -> {201, Poison.encode!(Simulation.recipe(:simulation)), "application/json"}
        :error -> {406, "Not Acceptable", "text/html"}
      end

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, body)
  end

  get "/:admin/restart" when admin == @admin_domain do
    Simulation.restart()
    Process.sleep(10)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/:admin/routes" when admin == @admin_domain do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, Simulation.route(:simulation) |> Enum.join("\n"))
  end

  get "/:admin/routes_status" when admin == @admin_domain do
    body =
      for {route, simulation} <- Simulation.state(:simulation) do
        "#{route} #{simulation.status} #{simulation.latency}"
      end
      |> Enum.join("\n")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, body)
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

  def recipe_not_set(),
    do: "Recipe not set, please POST a recipe to /#{admin_domain()}/add_recipe"

  def recipe_not_set(path) do
    "Recipe not set at #{path}, please POST a recipe for this route to /#{admin_domain()}/add_recipe"
  end
end
