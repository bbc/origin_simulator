defmodule OriginSimulator.RecipeTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Recipe

  test "Parse valid JSON" do
    assert Recipe.parse({:ok, ~s[{"random_content": "123kb"}], nil}) ==  %OriginSimulator.Recipe{random_content: "123kb"}
  end

  test "Given some headers it adds them to the recipe" do
    assert Recipe.parse({:ok, ~s[{"headers": {"host": "www.example.com"}}], nil}) == %OriginSimulator.Recipe{headers: %{"host" => "www.example.com"}}
  end
end
