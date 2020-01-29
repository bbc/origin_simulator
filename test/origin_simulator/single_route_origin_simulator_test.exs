defmodule SingleRouteOriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures
  import TestHelpers

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

      conn(:get, payload["route"])
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/random_path")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set_message("/random_path"))
    end

    test "for default route", %{payload_no_route: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, Recipe.default_route())
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())

      conn(:get, "/sport/tennis/51291122")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "for arbitrary wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock())
    end

    test "error message due to non-matching wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/cbbc")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set_message("/cbbc"))
    end
  end

  describe "GET page body" do
    setup [:body_payload, :body_payload_no_route]

    test "for a route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, payload["route"])
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "error message due to non-matching route", %{payload: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/random_path")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set_message("/random_path"))
    end

    test "for default route", %{payload_no_route: payload} do
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, Recipe.default_route())
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "for '/*' route", %{payload: payload} do
      payload = Map.put(payload, "route", "/*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))

      conn(:get, "/sport/tennis/51291122")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "for arbitrary wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/news/uk-politics-51287430")
      |> OriginSimulator.call([])
      |> assert_status_body(200, body_mock(type: :json))
    end

    test "error message due to non-matching wildcard route", %{payload: payload} do
      payload = Map.put(payload, "route", "/news*")
      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      conn(:get, "/sport")
      |> OriginSimulator.call([])
      |> assert_status_body(406, recipe_not_set_message("/sport"))
    end
  end
end
