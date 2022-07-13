defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload, Simulation, Plug.ResponseCounter}

  plug(ResponseCounter)
  plug(:match)
  plug(:dispatch)

  forward("/_admin", to: OriginSimulator.AdminRouter)

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
    {status, latency, payload_id} = Simulation.state(:simulation, route)

    sleep(latency)

    {:ok, body} = Payload.body(:payload, status, conn.request_path, payload_id)

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
