defmodule OriginSimulator.AdminRouter do
  use Plug.Router

  alias OriginSimulator.{Recipe, Simulation, Counter}

  plug(:match)
  plug(:dispatch)

  get "/status" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/current_recipe" do
    recipes = Simulation.recipe(:simulation)
    msg = if recipes == [], do: OriginSimulator.recipe_not_set(), else: recipes

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

  # TODO: consider ways to bifurcate counts per route, using
  # OTP state to store count rather than a Plug 
  get "/current_count" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(Counter.value()))
  end

  post "/add_recipe" do
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

  get "/restart" do
    Simulation.restart()
    Process.sleep(10)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/routes" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, Simulation.route(:simulation) |> Enum.join("\n"))
  end

  get "/routes_status" do
    body =
      for {route, simulation} <- Simulation.state(:simulation) do
        "#{route} #{simulation.status} #{simulation.latency}"
      end
      |> Enum.join("\n")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, body)
  end
end
