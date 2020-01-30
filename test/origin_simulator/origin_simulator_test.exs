defmodule OriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures
  import TestHelpers

  doctest OriginSimulator

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET /status" do
    test "will return 'OK'" do
      conn(:get, "/status")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "ok!")
      |> assert_resp_header({"content-type", ["text/plain; charset=utf-8"]})
    end
  end

  describe "GET /current_recipe" do
    test "will return an error message if payload has not been set" do
      conn(:get, "/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "\"Not set, please POST a recipe to /add_recipe\"")
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the payload if set" do
      payload = [origin_recipe()] |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the payload if set for ranged latencies" do
      payload = [origin_recipe_range_latency()] |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the headers in the payload when provided" do
      payload = [origin_recipe_headers()] |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return multi-recipe payload if set" do
      payload = multi_route_origin_recipes() |> Poison.encode!()

      conn(:post, "/add_recipe", payload)
      |> OriginSimulator.call([])
      |> assert_status_body(201, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end
  end

  describe "GET page" do
    test "will return the origin page" do
      payload = origin_recipe() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the origin page with random latency within range" do
      payload = origin_recipe_range_latency() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the parsed body content" do
      payload = body_recipe() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the parsed body content with respond headers" do
      payload = body_recipe_headers() |> Poison.encode!()
      expected_header = body_recipe_headers().headers["response-header"]

      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
      |> assert_resp_header({"response-header", [expected_header]})
    end

    test "will return random content of the parsed size" do
      payload = random_content_payload() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert String.length(conn.resp_body) == 50 * 1024
    end

    test "will return an error message if recipe has not been set" do
      conn(:get, "/")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set_message("/"))
    end
  end

  describe "POST page" do
    test "will return the origin page" do
      payload = origin_recipe() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:post, "/", "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
      |> assert_resp_header({"content-type", ["text/html; charset=utf-8"]})
    end

    test "will return the passed content" do
      payload = body_recipe() |> Poison.encode!()
      conn(:post, "/add_recipe", payload) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:post, "/", "")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end
  end
end
