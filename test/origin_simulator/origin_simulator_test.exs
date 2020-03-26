defmodule OriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures
  import Fixtures.Recipes
  import TestHelpers
  import OriginSimulator, only: [recipe_not_set: 1]

  doctest OriginSimulator

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET / when a recipe is set" do
    test "will return the origin page" do
      payload = origin_recipe() |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the origin page with random latency within range" do
      payload = origin_recipe_range_latency() |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the parsed body content" do
      payload = body_recipe() |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the parsed body content with respond headers" do
      headers = %{"response-header" => "123"}
      payload = body_recipe(headers) |> Poison.encode!()

      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
      |> assert_resp_header({"response-header", [headers["response-header"]]})
    end

    test "will return gzip parsed body with appropriate headers" do
      headers = %{
        "cache-control" => "public, max-age=30",
        "connection" => "keepalive",
        "content-encoding" => "gzip",
        "content-type" => "application/json; charset=utf-8"
      }

      payload = body_recipe(headers) |> Poison.encode!()

      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json) |> :zlib.gzip())
      |> assert_resp_header({"cache-control", ["public, max-age=30"]})
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
      |> assert_resp_header({"content-encoding", ["gzip"]})
      |> assert_resp_header({"connection", ["keepalive"]})
    end

    test "will return random content of the parsed size" do
      payload = random_content_recipe("50kb") |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert String.length(conn.resp_body) == 50 * 1024
    end

    test "will return gzip random content with appropriate headers" do
      headers = %{
        "cache-control" => "public, max-age=30",
        "connection" => "keepalive",
        "content-encoding" => "gzip",
        "content-type" => "text/html; charset=utf-8"
      }

      payload = random_content_recipe("50kb", headers) |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert String.length(conn.resp_body |> :zlib.gunzip()) == 50 * 1024
    end
  end

  describe "POST / when a recipe is set" do
    test "will return the origin page" do
      payload = origin_recipe() |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:post, "/", "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the parsed body content" do
      payload = body_recipe() |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:post, "/", "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end
  end

  describe "when a recipe is not set" do
    test "GET / will return an error message" do
      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/"))
    end

    test "POST / will return an error message" do
      conn(:post, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/"))
    end
  end

  describe "when a recipe with route and origin is set" do
    setup :origin_payload

    test "GET routed page will return the origin page", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, payload["route"])
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "GET routed (wildcard) page will return the origin page", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "POST \"\" to routed page will return the origin page", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:post, payload["route"], "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "POST \"\" to routed (wildcard) page will return the origin page", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:post, "/news/uk-politics-51287430", "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "GET /* will return the origin page", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/any_path")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "GET non-matching route will return error", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/not_matching_random_path")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/not_matching_random_path"))
    end

    test "GET non-matching route (widlcard) will return error", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/cbbc")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/cbbc"))
    end
  end

  describe "when a recipe with route and body is set" do
    setup :body_payload

    test "GET routed page will return the body", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, payload["route"])
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "GET routed (wildcard) page will return the body", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "POST \"\" to routed page will return the body", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:post, payload["route"])
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "POST \"\" to routed (wildcard) page will return the body", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:post, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "GET /* will return the body", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))

      conn(:get, "/sport/tennis/51291122")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "GET non-matching route will return error", %{payload: payload} do
      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/random_path")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/random_path"))
    end

    test "GET non-matching route (widlcard) will return error", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/sport")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set("/sport"))
    end
  end

  describe "when a recipe with multiple routes and origins is set" do
    test "GET /* route will return the origin page" do
      payload = [
        %{
          "route" => "/*",
          "origin" => "https://www.bbc.co.uk/news",
          "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
        }
      ]

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      conn(:get, "/any_path")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "GET multiple routes will return the origin page" do
      payload = multi_route_origin_payload()

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload))
      |> OriginSimulator.call([])

      Process.sleep(20)

      for route <- payload |> Enum.map(& &1["route"]) do
        conn(:get, route)
        |> OriginSimulator.call([])
        |> assert_status_body(200, body_mock())
      end
    end
  end
end
