defmodule OriginSimulator.RecipeTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Recipe

  test "Parse valid JSON" do
    json = ~s[{"random_content": "123kb"}]
    assert Recipe.parse({:ok, json, nil}) == %Recipe{random_content: "123kb"}
  end

  test "Given some headers it adds them to the recipe" do
    json = ~s[{"headers": {"host": "www.example.com"}}]
    assert Recipe.parse({:ok, json, nil}) == %Recipe{headers: %{"host" => "www.example.com"}}
  end

  test "default_route/0 returns correct value" do
    recipe = %Recipe{}
    assert Recipe.default_route() == recipe.route
  end
end
