defmodule OriginSimulator.AdminRouterTest do
  use ExUnit.Case
  use Plug.Test

  import Fixtures.Recipes
  import TestHelpers

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET /#{admin_domain()}/status" do
    test "will return 'OK'" do
      conn(:get, "/#{admin_domain()}/status")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "ok!")
      |> assert_resp_header({"content-type", ["text/plain; charset=utf-8"]})
    end

    test "will not match request with similar path and get the default page" do
      conn(:get, "/another_domain/status")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end
  end

  describe "GET /#{admin_domain()}/routes" do
    test "will return default route" do
      conn(:get, "/#{admin_domain()}/routes")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "/*")
      |> assert_resp_header({"content-type", ["text/plain; charset=utf-8"]})
    end

    test "will return the default content" do
      conn(:get, "/another_domain/routes")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end

    test "will not increment response counter" do
      current_count = OriginSimulator.Counter.value().total_requests
      conn(:get, "/#{admin_domain()}/routes") |> OriginSimulator.call([])

      assert OriginSimulator.Counter.value().total_requests == current_count
    end
  end

  describe "GET /#{admin_domain()}/routes_status" do
    test "will return default route" do
      conn(:get, "/#{admin_domain()}/routes_status")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "/* 200 100")
      |> assert_resp_header({"content-type", ["text/plain; charset=utf-8"]})
    end

    test "will return the default page" do
      conn(:get, "/another_domain/routes_status")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end
  end

  describe "GET /#{admin_domain()}/restart" do
    test "will return default route" do
      conn(:get, "/_admin/restart")
      |> OriginSimulator.call([])
      |> assert_status_body(200, "ok!")
      |> assert_resp_header({"content-type", ["text/plain; charset=utf-8"]})
    end

    test "will return the default content" do
      conn(:get, "/another_domain/restart")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end
  end

  describe "GET /#{admin_domain()}/current_recipe" do
    test "will return the default recipe" do
      conn(:get, "/#{admin_domain()}/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, [default_recipe()] |> Poison.encode!())
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the default content" do
      conn(:get, "/another_domain/current_recipe")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end

    test "will return the payload if set" do
      payload = [origin_recipe()] |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/#{admin_domain()}/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the payload if set for ranged latencies" do
      payload = [origin_recipe_range_latency()] |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/#{admin_domain()}/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return the headers in the payload when provided" do
      payload = [origin_recipe()] |> Poison.encode!()
      conn(:post, "/#{admin_domain()}/add_recipe", payload) |> OriginSimulator.call([])

      conn(:get, "/#{admin_domain()}/current_recipe")
      |> OriginSimulator.call([])
      |> assert_status_body(200, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    test "will return multi-recipe payload if set" do
      payload = multi_route_origin_recipes() |> Poison.encode!()

      conn(:post, "/#{admin_domain()}/add_recipe", payload)
      |> OriginSimulator.call([])
      |> assert_status_body(201, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end
  end

  describe "POST /#{admin_domain()}/add_recipe" do
    test "will handle recipe upload" do
      payload = [origin_recipe()] |> Poison.encode!()

      conn(:post, "/#{admin_domain()}/add_recipe", payload)
      |> OriginSimulator.call([])
      |> assert_status_body(201, payload)
      |> assert_resp_header({"content-type", ["application/json; charset=utf-8"]})
    end

    # TODO: need fixing, see comment near `post "/:admin/add_recipe"`
    # in `lib/origin_simulator.ex` ~line 42
    test "will mhandle malformed recipe", do: true

    test "will return the default content" do
      conn(:get, "/another_domain/add_recipe")
      |> OriginSimulator.call([])
      |> assert_default_page()
    end
  end
end
