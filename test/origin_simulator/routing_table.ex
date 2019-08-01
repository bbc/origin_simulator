defmodule OriginSimulator.RoutingTableTest do
  use ExUnit.Case, async: true
  alias OriginSimulator.{RoutingTable,RecipeRoute}

  setup do
    routing_table = start_supervised!(RoutingTable)

    %{routing_table: routing_table}
  end

  describe "storing the routing table" do
    test "update the routing table if all of the routes are valid", %{routing_table: routing_table} do
      assert :ok == RoutingTable.update_routing_table(routing_table, [%RecipeRoute{pattern: "/*"}])
    end

    test "return an error if any of the routes are invalid", %{routing_table: routing_table} do
      assert :error == RoutingTable.update_routing_table(routing_table, [%RecipeRoute{pattern: "*/"}])
    end
  end

  describe "find route" do
    test "finds matches", %{routing_table: routing_table} do
      RoutingTable.update_routing_table(routing_table, [%RecipeRoute{pattern: "/foo"}])

      assert RoutingTable.find_route(routing_table, "/foo") == {:ok, "/foo"}
      assert RoutingTable.find_route(routing_table, "/foobar") == {:ok, "/foo"}
    end

    test "with multiple routes", %{routing_table: routing_table} do
      RoutingTable.update_routing_table(routing_table, [
            %RecipeRoute{pattern: "/foo"},
            %RecipeRoute{pattern: "/bar"}
          ])

      assert RoutingTable.find_route(routing_table, "/bar") == {:ok, "/bar"}
    end


    test "finds the first matching route", %{routing_table: routing_table} do
      RoutingTable.update_routing_table(routing_table, [
            %RecipeRoute{pattern: "/foo"},
            %RecipeRoute{pattern: "/foobar"}
          ])

      assert RoutingTable.find_route(routing_table, "/foo") == {:ok, "/foo"}
    end

    test "return an error if the pattern doesn't match any of the routes", %{routing_table: routing_table} do
      RoutingTable.update_routing_table(routing_table, [])

      assert RoutingTable.find_route(routing_table, "/foo") == {:error, "The request path doesn't match any of the defined routes"}
    end
  end
end
