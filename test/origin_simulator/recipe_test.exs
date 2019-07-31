defmodule OriginSimulator.RecipeTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.{Recipe,RecipeRoute}

  test "Parse valid JSON" do
    assert Recipe.parse({:ok, ~s([{"random_content": "123kb"}]), nil}) == [%RecipeRoute{random_content: "123kb"}]
  end

  test "Have a default pattern" do
    %RecipeRoute{pattern: expected} = List.first(Recipe.parse({:ok, ~s([{"random_content": "123kb"}]), nil}))

    assert expected == "/*"
  end

  test "Supports multiple routes" do
    assert Recipe.parse({:ok, ~s([{"random_content": "123kb"}, {"body": "test"}]), nil}) == [%RecipeRoute{random_content: "123kb"}, %RecipeRoute{body: "test"}]
  end
end
