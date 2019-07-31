defmodule OriginSimulator.Recipe do
  alias OriginSimulator.{RecipeRoute}

  def parse({:ok, body, _conn}) do
    Poison.decode!(body, as: [%RecipeRoute{}])
  end
end
