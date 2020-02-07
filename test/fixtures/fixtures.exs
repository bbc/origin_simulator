defmodule Fixtures do
  alias OriginSimulator.HTTPMockClient
  alias OriginSimulator.Recipe

  def body_mock(opts \\ []) do
    [mock: mock, type: type] = [mock: HTTPMockClient, type: :html] |> Keyword.merge(opts)
    {:ok, %{body: body}} = mock.get("/", type: type)
    body
  end

  def http_error_message(status), do: "Error #{status}"

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

  def origin_payload() do
    %{
      "origin" => "https://www.bbc.co.uk/news",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
      "route" => "/news"
    }
  end

  def origin_payload(context), do: {:ok, Map.put(context, :payload, origin_payload())}

  def body_payload() do
    %{
      "body" => "{\"hello\":\"world\"}",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
      "route" => "/news"
    }
  end

  def body_payload(context), do: {:ok, Map.put(context, :payload, body_payload())}

  def random_content_payload() do
    %{
      "random_content" => "50kb",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def multi_route_origin_payload() do
    [
      %{
        "route" => "/sport",
        "origin" => "https://www.bbc.co.uk/sport",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "0ms"}]
      },
      %{
        "route" => "/news",
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "0ms"}]
      },
      %{
        "route" => "/news/entertainment_and_arts",
        "origin" => "https://www.bbc.co.uk/news/entertainment_and_arts",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "0ms"}]
      },
      %{
        "route" => "/weather",
        "origin" => "https://www.bbc.co.uk/weather",
        "stages" => [%{"at" => 0, "status" => 200, "latency" => "0ms"}]
      }
    ]
  end

  def multi_route_mixed_payload() do
    [
      %{
        "route" => "/example/endpoint",
        "body" => "Example body",
        "stages" => [
          %{"at" => 0, "status" => 200, "latency" => "400ms"},
          %{"at" => "1s", "status" => 503, "latency" => "100ms"}
        ]
      },
      %{
        "route" => "/news",
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [
          %{"at" => 0, "status" => 404, "latency" => "50ms"},
          %{"at" => "2s", "status" => 503, "latency" => "2s"},
          %{"at" => "4s", "status" => 200, "latency" => "100ms"}
        ]
      },
      %{
        "route" => "/*",
        "body" => "Error - not defined",
        "stages" => [%{"at" => 0, "status" => 406, "latency" => "0ms"}]
      }
    ]
  end
end
