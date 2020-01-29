defmodule SingleRouteOriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures

  alias OriginSimulator.Recipe

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET page origin" do
    setup [:origin_payload, :origin_payload_no_route]

    test "for a route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = payload["route"]
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock()
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      path = "/random_path"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406
      assert conn.resp_body == recipe_not_set_message(path)
    end

    test "for default route", %{payload_no_route: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, Recipe.default_route())
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock()
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock()

      new_status = 500
      new_stages = [%{"at" => 0, "status" => new_status, "latency" => 0}]
      payload = Map.put(payload, "stages", new_stages)

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/politcs/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == new_status
      assert conn.resp_body == http_error_message(new_status)
    end

    test "for arbitrary wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock()
    end

    test "error message due to non-matching wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      path = "/cbbc"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406
      assert conn.resp_body == recipe_not_set_message(path)
    end
  end

  describe "GET page body" do
    setup [:body_payload, :body_payload_no_route]

    test "for a route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      req_path = payload["route"]
      conn = conn(:get, req_path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock(type: :json)
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      path = "/random_path"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406
      assert conn.resp_body == recipe_not_set_message(path)
    end

    test "for default route", %{payload_no_route: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, Recipe.default_route())
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock(type: :json)
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock(type: :json)

      new_status = 500
      new_stages = [%{"at" => 0, "status" => new_status, "latency" => 0}]
      payload = Map.put(payload, "stages", new_stages)

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/politcs/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == new_status
      assert conn.resp_body == http_error_message(new_status)
    end

    test "for arbitrary wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/news/sport/id")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == body_mock(type: :json)
    end

    test "error message due to non-matching wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      path = "/"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 406
      assert conn.resp_body == recipe_not_set_message(path)
    end
  end
end
