defmodule OriginSimulator do
  use Plug.Router
  alias OriginSimulator.{Payload,RecipeBook,Simulation,PlugResponseCounter,Counter}
  plug(PlugResponseCounter)

  plug(:match)
  plug(:dispatch)

  get "/status" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok!")
  end

  get "/current_recipe" do
    msg = Simulation.recipe_book(:simulation) || "Not set, please POST a recipe book to /add_recipe"

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
    Simulation.restart
    Process.sleep(10)

    recipe_book = RecipeBook.parse(Plug.Conn.read_body(conn))
    Simulation.add_recipe_book(:simulation, recipe_book)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Poison.encode!(Simulation.recipe_book(:simulation)))
  end

  get "/*glob" do
    serve_payload(conn)
  end

  post "/*glob" do
    serve_payload(conn)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp serve_payload(conn) do
    route = conn.request_path
    {:ok, status, latency} = Simulation.state(:simulation, route)

    sleep(latency)

    {:ok, body} = Payload.body(:payload, status, route)

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
