defmodule OriginSimulator.SimulationTest do
  use ExUnit.Case

  alias OriginSimulator.{Simulation,RecipeRoute}

  # def test_recipe() do
  #   [RecipeRoute{origin: "foo",
  #                stages: [%{"at" => 0, "status" => 200, "latency" => "1s"}]}]
  # end

  # def test_range_recipe() do
  #   [RecipeRoute{origin: "foo",
  #                stages: [%{"at" => 0, "status" => 200, "latency" => "1s..1200ms"}]}]
  # end

  # def test_recipe_with_multiple_stages() do
  #   [RecipeRoute{origin: "foo",
  #                stages: [%{"at" => 0, "status" => 200, "latency" => "0s"},
  #                         %{"at" => "60ms", "status" => 503, "latency" => "1s"}]}]
  # end

  # describe "with loaded recipe" do
  #   setup do
  #     Simulation.add_recipe(:simulation, test_recipe())
  #     Process.sleep(5)
  #   end

  #   test "state() returns a tuple with http status and latency in ms" do
  #     assert Simulation.state(:simulation) == {200, 1000}
  #   end

  #   test "recipe() returns the loaded recipe" do
  #     assert Simulation.recipe(:simulation) == test_recipe()
  #   end
  # end

  # describe "with a recipe containing a range" do
  #   setup do
  #     Simulation.add_recipe(:simulation, test_range_recipe())
  #     Process.sleep(5)
  #   end

  #   test "state() returns a tuple with http status and latency in ms" do
  #     assert Simulation.state(:simulation) == {200, 1000..1200}
  #   end

  #   test "recipe() returns the loaded recipe" do
  #     assert Simulation.recipe(:simulation) == test_range_recipe()
  #   end
  # end

  # describe "with a recipe containing multiple stages" do
  #   setup do
  #     Simulation.add_recipe(:simulation, test_recipe_with_multiple_stages())
  #     Process.sleep(5)
  #   end

  #   test "state() returns a tuple with http status and latency in ms" do
  #     assert Simulation.state(:simulation) == {200, 0}
  #     Process.sleep(80)
  #     assert Simulation.state(:simulation) == {503, 1000}
  #   end

  #   test "recipe() returns the loaded recipe" do
  #     assert Simulation.recipe(:simulation) == test_recipe_with_multiple_stages()
  #   end
  # end

  # describe "with no recipe loaded" do
  #   setup do
  #     Simulation.restart()
  #     Process.sleep(5)
  #   end

  #   test "state() returns a tuple with default values" do
  #     assert Simulation.state(:simulation) == {406, 0}
  #   end

  #   test "recipe() returns nil" do
  #     assert Simulation.recipe(:simulation) == nil
  #   end
  # end
end
