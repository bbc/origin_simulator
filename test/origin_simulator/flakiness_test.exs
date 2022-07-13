defmodule OriginSimulator.FlakinessTest do
  use ExUnit.Case, async: true
  import Fixtures.Recipes
  alias OriginSimulator.{Flakiness, Simulation}

  @default_interval 1000
  @simulation_server :simulation

  test "new/0 returns a new Flakiness struct" do
    assert Flakiness.new() == %Flakiness{interval: nil, payload: [], route: "/*", status: []}
  end

  test "new/2 returns a Flakiness struct for random payload series and route" do
    flakiness = Flakiness.new([150, 155, 160], "/an_origin_route")

    assert flakiness.payload == [150, 155, 160]
    assert flakiness.route == "/an_origin_route"
  end

  test "state/0 returns the current flakiness state" do
    Flakiness.new([150, 155, 160], "/an_origin_route")
    |> Flakiness.set()

    assert Flakiness.state() == %Flakiness{payload: [150, 155, 160], route: "/an_origin_route"}
  end

  test "set/1 flakiness" do
    previous_flakiness = Flakiness.state()
    new_flakiness = Flakiness.new([500, 505, 510], "/route_a")

    Flakiness.set(new_flakiness)

    refute Flakiness.state() == previous_flakiness
    assert Flakiness.state() == %Flakiness{payload: [500, 505, 510], route: "/route_a"}
  end

  test "start/2 flakiness for a route" do
    recipe = random_content_recipe("10kb..50kb", %{"content-encoding" => "gzip"}, "/route_for_random_payloads")

    Simulation.add_recipe(@simulation_server, recipe)
    Process.sleep(5)

    assert Flakiness.state() == %Flakiness{
             interval: @default_interval,
             payload: [10, 15, 20, 25, 30, 35, 40, 45, 50],
             route: "/route_for_random_payloads"
           }
  end

  test "current flakiness payload is within the intended random range" do
    recipe = random_content_recipe("50kb..100kb", %{"content-encoding" => "gzip"}, "/route_for_random_payloads")

    Simulation.add_recipe(@simulation_server, recipe)
    Process.sleep(50)

    {_status, _latency, {_route, payload}} = Simulation.state(@simulation_server, "/route_for_random_payloads")

    assert payload in Flakiness.state().payload
  end
end
