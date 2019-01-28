defmodule OriginSimulator.SimulationTest do
  use ExUnit.Case

  alias OriginSimulator.Simulation

  def test_recipe() do
    %OriginSimulator.Recipe{origin: "foo",
                            stages: [%{"at" => 0, "status" => 200, "latency" => 1000}]}
  end

  describe "with loaded recipe" do
    setup do
      Simulation.add_recipe(:simulation, test_recipe())
      Process.sleep(10)
    end

    test "state() returns a tuple with http status and latency in ms" do
      assert Simulation.state(:simulation) == {200, 1000}
    end

    test "recipe() returns the loaded recipe" do
      assert Simulation.recipe(:simulation) == test_recipe()
    end
  end

  describe "with no recipe loaded" do
    setup do
      Simulation.restart(:simulation)
      Process.sleep(100)
    end

    test "state() returns a tuple with default values" do
      assert Simulation.state(:simulation) == {406, 0}
    end

    test "recipe() returns nil" do
      assert Simulation.recipe(:simulation) == nil
    end
  end
end
