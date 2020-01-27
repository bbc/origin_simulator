defmodule OriginSimulator.SimulationTest do
  use ExUnit.Case

  import Fixtures

  alias OriginSimulator.{Simulation, Recipe}

  describe "with loaded recipe" do
    setup do
      stages = [%{"at" => 0, "status" => 200, "latency" => "1s"}]
      recipe = test_recipe(origin: "foo", stages: stages)
      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe}
    end

    test "state() returns a tuple with http status and latency in ms" do
      assert Simulation.state(:simulation) == {200, 1000}
    end

    test "recipe() returns the loaded recipe", %{recipe: recipe} do
      assert Simulation.recipe(:simulation) == recipe
    end

    test "recipe() returns route", %{recipe: recipe} do
      assert Simulation.route(:simulation) == recipe |> Map.get(:route)
    end
  end

  describe "with a recipe containing a range" do
    setup do
      stages = [%{"at" => 0, "status" => 200, "latency" => "1s..1200ms"}]
      recipe = test_recipe(origin: "foo", stages: stages)
      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe}
    end

    test "state() returns a tuple with http status and latency in ms" do
      assert Simulation.state(:simulation) == {200, 1000..1200}
    end

    test "recipe() returns the loaded recipe", %{recipe: recipe} do
      assert Simulation.recipe(:simulation) == recipe
    end
  end

  describe "with a recipe containing multiple stages" do
    setup do
      stages = [
        %{"at" => 0, "status" => 200, "latency" => "0s"},
        %{"at" => "60ms", "status" => 503, "latency" => "1s"}
      ]

      recipe = test_recipe(origin: "foo", stages: stages)
      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe}
    end

    test "state() returns a tuple with http status and latency in ms" do
      assert Simulation.state(:simulation) == {200, 0}
      Process.sleep(80)
      assert Simulation.state(:simulation) == {503, 1000}
    end

    test "recipe() returns the loaded recipe", %{recipe: recipe} do
      assert Simulation.recipe(:simulation) == recipe
    end
  end

  describe "with no recipe loaded" do
    setup do
      Simulation.restart()
      Process.sleep(5)
    end

    test "state() returns a tuple with default values" do
      assert Simulation.state(:simulation) == {406, 0}
    end

    test "recipe() returns nil" do
      assert Simulation.recipe(:simulation) == nil
    end

    test "route() returns default route" do
      assert Simulation.route(:simulation) == Recipe.default_route()
    end
  end
end
