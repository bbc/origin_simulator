defmodule OriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures

  doctest OriginSimulator

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET /status" do
    test "will return 'OK'" do
      conn = conn(:get, "/status") |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body == "ok!"
    end
  end

  describe "GET /current_recipe" do
    test "will return an error message if payload has not been set" do
      conn = conn(:get, "/current_recipe") |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == "\"Not set, please POST a recipe to /add_recipe\""
    end

    test "will return the payload if set" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "100ms"}],
        "random_content" => nil,
        "body" => nil,
        "headers" => %{},
        "route" => nil
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      conn = conn(:get, "/current_recipe")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert Poison.decode!(conn.resp_body) == payload
    end

    test "will return the payload if set for ranged latencies" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "100ms..200ms"}],
        "random_content" => nil,
        "body" => nil,
        "headers" => %{},
        "route" => nil
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      conn = conn(:get, "/current_recipe")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert Poison.decode!(conn.resp_body) == payload
    end

    test "will return the headers in the payload when provided" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "100ms..200ms"}],
        "random_content" => nil,
        "body" => nil,
        "headers" => %{"X-Foo" => "bar"},
        "route" => nil
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      conn = conn(:get, "/current_recipe")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert Poison.decode!(conn.resp_body) == payload
    end

    # multiple recipes posting is currently not supported
    test "/add_recipe returns error message if multiple recipes is posted" do
      payload = [
        %{
          "route" => "/example/endpoint",
          "body" => "Example body",
          "stages" => [
            %{"at" => 0, "status" => 200, "latency" => "400ms"},
            %{"at" => "1s", "status" => 503, "latency" => "100ms"}
          ]
        },
        %{
          "route" => "/news",
          "origin" => "https://www.bbc.co.uk/news",
          "stages" => [
            %{"at" => 0, "status" => 404, "latency" => "50ms"},
            %{"at" => "2s", "status" => 503, "latency" => "2s"},
            %{"at" => "4s", "status" => 200, "latency" => "100ms"}
          ]
        },
        %{
          "route" => "/*",
          "body" => "Error - not defined",
          "stages" => [%{"at" => 0, "status" => 406, "latency" => "0ms"}]
        }
      ]

      conn = conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 406
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == "Not Acceptable"
    end
  end

  describe "GET page" do
    test "will return the origin page" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == body_mock()
    end

    test "will return the origin page with random latency within range" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "10ms..50ms"}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == body_mock()
    end

    test "will return the passed content" do
      payload = %{
        "body" => "{\"hello\":\"world\"}",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == body_mock(type: :json)
    end

    test "will return the passed content with respond headers" do
      payload = %{
        "body" => "{\"hello\":\"world\"}",
        "headers" => %{"response-header" => "Value123"},
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert get_resp_header(conn, "response-header") == ["Value123"]
      assert conn.resp_body == body_mock(type: :json)
    end

    test "will return random content of the passed size" do
      payload = %{
        "random_content" => "50kb",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert String.length(conn.resp_body) == 50 * 1024
    end

    test "will return an error message if recipe has not been set" do
      conn = conn(:get, "/") |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 406
      assert conn.resp_body == recipe_not_set_message()
    end
  end

  describe "POST page" do
    test "will return the origin page" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:post, "/", "")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == body_mock()
    end

    test "will return the passed content" do
      payload = %{
        "body" => "{\"hello\":\"world\"}",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn = conn(:post, "/", "")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == body_mock(type: :json)
    end
  end
end
