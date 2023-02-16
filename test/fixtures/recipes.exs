defmodule Fixtures.Recipes do
  alias OriginSimulator.Recipe

  def recipe(overrides \\ []), do: struct(Recipe, Keyword.merge(recipe_defaults(), overrides))
  defp recipe_defaults(), do: %Recipe{} |> Map.to_list() |> tl

  def origin_recipe(headers \\ %{}) do
    %Recipe{
      origin: "https://www.bbc.co.uk/news",
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
      headers: headers
    }
  end

  def origin_recipe_range_latency() do
    %Recipe{
      origin: "https://www.bbc.co.uk/news",
      stages: [%{"at" => 0, "status" => 200, "latency" => "100ms..200ms"}]
    }
  end

  def body_recipe(headers \\ %{}) do
    %Recipe{
      body: "{\"hello\":\"world\"}",
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
      headers: headers
    }
  end

  def random_content_recipe(size \\ "50kb", headers \\ %{}) do
    %Recipe{
      random_content: size,
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
      headers: headers
    }
  end

  def multi_route_origin_recipes() do
    [default_recipe()] ++ [
      %Recipe{
        origin: "https://www.bbc.co.uk/news",
        stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
        route: "/news"
      },
      %Recipe{
        origin: "https://www.bbc.co.uk/sport",
        stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
        route: "/sport"
      },
      %Recipe{
        origin: "https://www.bbc.co.uk/weather",
        stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
        route: "/weather"
      },
      %Recipe{
        origin: "https://www.bbc.co.uk/news/entertainment_and_arts",
        stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
        route: "news/entertainment_and_arts"
      }
    ]
  end

  def default_recipe do
    File.read!(File.cwd!() <> "/examples/default.json") |> OriginSimulator.Recipe.parse()
  end
end
