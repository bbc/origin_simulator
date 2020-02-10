defmodule Fixtures.Recipes do
  alias OriginSimulator.Recipe

  def recipe(overrides \\ []), do: struct(Recipe, Keyword.merge(recipe_defaults(), overrides))
  defp recipe_defaults(), do: %Recipe{} |> Map.to_list() |> tl

  def origin_recipe() do
    %Recipe{
      origin: "https://www.bbc.co.uk/news",
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def origin_recipe_range_latency() do
    %Recipe{
      origin: "https://www.bbc.co.uk/news",
      stages: [%{"at" => 0, "status" => 200, "latency" => "100ms..200ms"}]
    }
  end

  def origin_recipe_headers() do
    %Recipe{
      origin: "https://www.bbc.co.uk/news",
      stages: [%{"at" => 0, "status" => 200, "latency" => "100ms..200ms"}],
      headers: %{"X-Foo" => "bar"}
    }
  end

  def body_recipe() do
    %Recipe{
      body: "{\"hello\":\"world\"}",
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def body_recipe_headers() do
    %Recipe{
      body: "{\"hello\":\"world\"}",
      stages: [%{"at" => 0, "status" => 200, "latency" => 0}],
      headers: %{"response-header" => "Value123"}
    }
  end

  def multi_route_origin_recipes() do
    [
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
end