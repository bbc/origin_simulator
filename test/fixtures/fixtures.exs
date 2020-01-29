defmodule Fixtures do
  alias OriginSimulator.HTTPMockClient
  alias OriginSimulator.Recipe

  def body_mock(opts \\ []) do
    [mock: mock, type: type] = [mock: HTTPMockClient, type: :html] |> Keyword.merge(opts)
    {:ok, %{body: body}} = mock.get("/", type: type)
    body
  end

  def recipe_not_set_message(), do: "Recipe not set, please POST a recipe to /add_recipe"

  def recipe_not_set_message(path) do
    "Recipe not set at #{path}, please POST a recipe for this route to /add_recipe"
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

  def origin_payload() do
    %{
      "origin" => "https://www.bbc.co.uk/news",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
      "route" => "/news"
    }
  end

  def origin_payload_no_route() do
    %{
      "origin" => "https://www.bbc.co.uk/news",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def origin_payload(context), do: {:ok, Map.put(context, :payload, origin_payload())}

  def origin_payload_no_route(context) do
    {:ok, Map.put(context, :payload_no_route, origin_payload_no_route())}
  end

  def body_payload() do
    %{
      "body" => "{\"hello\":\"world\"}",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}],
      "route" => "/news"
    }
  end

  def body_payload_no_route() do
    %{
      "body" => "{\"hello\":\"world\"}",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def body_payload(context), do: {:ok, Map.put(context, :payload, body_payload())}

  def body_payload_no_route(context) do
    {:ok, Map.put(context, :payload_no_route, body_payload_no_route())}
  end

  def random_content_payload() do
    %{
      "random_content" => "50kb",
      "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
    }
  end

  def multi_origin_payload() do
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
