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

      {:ok, payload: origin_payload}
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
  end

  describe "GET page body" do
    setup do
      body_payload = %{
        "body" => "{\"hello\":\"world\"}",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
        "route" => "/news"
      }

      {:ok, payload: body_payload}
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
  end
end
