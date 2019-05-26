defmodule OriginSimulator.RecipeTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Recipe

  test "Parse valid JSON" do
    assert Recipe.parse({:ok, ~s[{"random": "123kb"}], nil}) ==  %OriginSimulator.Recipe{random: "123kb"}
  end
end
