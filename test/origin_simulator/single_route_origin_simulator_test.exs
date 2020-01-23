defmodule SingleRouteOriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET page origin" do
    setup do
      origin_payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
        "route" => "/news"
      }

      origin_payload_default_route = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      {:ok,
       default_route: OriginSimulator.Recipe.default_route(),
       payload: origin_payload,
       payload_default_route: origin_payload_default_route}
    end

    test "for a route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = payload["route"]
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "some content from origin"
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = "/random_path"
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406

      assert conn.resp_body ==
               "Recipe not set at #{req_path}, please POST a recipe for this route to /add_recipe"
    end

    test "for default route", %{payload_default_route: payload, default_route: route} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, route)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "some content from origin"
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "some content from origin"

      new_status = 500
      new_stages = [%{"at" => 0, "status" => new_status, "latency" => 0}]
      payload = Map.put(payload, "stages", new_stages)

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/politcs/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == new_status
      assert conn.resp_body == "Error 500"
    end
  end

  describe "GET page body" do
    setup do
      body_payload = %{
        "body" => "{\"hello\":\"world\"}",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
        "route" => "/news"
      }

      body_payload_default_route = %{
        "body" => "{\"hello\":\"world\"}",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      {:ok,
       default_route: OriginSimulator.Recipe.default_route(),
       payload: body_payload,
       payload_default_route: body_payload_default_route}
    end

    test "for a route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = payload["route"]
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"hello\":\"world\"}"
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = "/random_path"
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406

      assert conn.resp_body ==
               "Recipe not set at #{req_path}, please POST a recipe for this route to /add_recipe"
    end

    test "for default route", %{payload_default_route: payload, default_route: route} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, route)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"hello\":\"world\"}"
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "{\"hello\":\"world\"}"

      new_status = 500
      new_stages = [%{"at" => 0, "status" => new_status, "latency" => 0}]
      payload = Map.put(payload, "stages", new_stages)

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/politcs/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == new_status
      assert conn.resp_body == "Error 500"
    end
  end
end
