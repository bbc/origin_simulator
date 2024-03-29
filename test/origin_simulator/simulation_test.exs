defmodule OriginSimulator.SimulationTest do
  use ExUnit.Case

  import Fixtures.Recipes

  alias OriginSimulator.{Simulation, Recipe}

  describe "with loaded recipe" do
    setup do
      stages = [%{"at" => 0, "status" => 200, "latency" => "1s"}]
      recipe = recipe(origin: "foo", stages: stages)

      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe, route: recipe.route}
    end

    test "state() returns a tuple with http status and latency in ms for a route", %{route: route} do
      assert Simulation.state(:simulation, route) == {200, 1000}
    end

    test "recipe() returns the loaded recipe for a route", %{recipe: recipe, route: route} do
      assert Simulation.recipe(:simulation, route) == recipe
    end

    test "route/2 returns matching route", %{recipe: recipe, route: route} do
      assert Simulation.route(:simulation, route) == recipe |> Map.get(:route)
    end

    test "route/2 returns matching wildcard route", %{recipe: recipe} do
      Simulation.add_recipe(:simulation, %{recipe | route: "/news*"})
      Process.sleep(5)

      assert Simulation.route(:simulation, "/news/uk-politics") == "/news*"
      assert Simulation.route(:simulation, "/sport") == "/*"
    end

    test "route/1 returns all routes", %{recipe: recipe} do
      Simulation.add_recipe(:simulation, %{recipe | route: "/random123123123*"})
      Process.sleep(5)

      assert length(Simulation.route(:simulation)) > 1
      assert Simulation.route(:simulation) |> Enum.member?("/random123123123*")
    end
  end

  describe "with a list of multiple recipes" do
    test "add_recipe() works with multiple recipes" do
      recipe =
        recipe(
          origin: "foo",
          stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
          route: "/news"
        )

      assert Simulation.add_recipe(:simulation, [
               recipe,
               %{recipe | route: "/sports"},
               %{recipe | route: "/weather"}
             ]) == :ok
    end
  end

  describe "with a recipe containing a range" do
    setup do
      stages = [%{"at" => 0, "status" => 200, "latency" => "1s..1200ms"}]
      recipe = recipe(origin: "foo", stages: stages)

      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe, route: recipe.route}
    end

    test "state() returns a tuple with http status and latency in ms", %{route: route} do
      assert Simulation.state(:simulation, route) == {200, 1000..1200}
    end

    test "recipe() returns the loaded recipe", %{recipe: recipe, route: route} do
      assert Simulation.recipe(:simulation, route) == recipe
    end
  end

  describe "with a recipe containing multiple stages" do
    setup do
      stages = [
        %{"at" => 0, "status" => 200, "latency" => "0s"},
        %{"at" => "60ms", "status" => 503, "latency" => "1s"}
      ]

      recipe = recipe(origin: "foo", stages: stages)
      Simulation.add_recipe(:simulation, recipe)
      Process.sleep(5)

      {:ok, recipe: recipe, route: recipe.route}
    end

    test "state() returns a tuple with http status and latency in ms", %{route: route} do
      assert Simulation.state(:simulation, route) == {200, 0}
      Process.sleep(80)
      assert Simulation.state(:simulation, route) == {503, 1000}
    end

    test "recipe() returns the loaded recipe", %{recipe: recipe, route: route} do
      assert Simulation.recipe(:simulation, route) == recipe
    end
  end

  describe "with only the default recipe loaded" do
    setup do
      Simulation.restart()
      Process.sleep(5)
    end

    test "state() returns a tuple with default values" do
      assert Simulation.state(:simulation, Recipe.default_route()) == {200, 100}
    end

    test "recipe() returns an empty list" do
      assert Simulation.recipe(:simulation) == [default_recipe()]
    end

    test "route() returns default route" do
      assert Simulation.route(:simulation, "/random_path") == "/*"
    end
  end
end
