defmodule OriginSimulator.RecipeBook do
  alias OriginSimulator.{Recipe}

  def parse({:ok, body, _conn}) do
    Poison.decode!(body, as: [%Recipe{}])
    # |> Enum.into(%{}, fn {route, recipe} -> {route, struct(%Recipe{}, recipe)} end)
  end
end
