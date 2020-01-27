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

  def http_error_message(status) do
    "Error #{status}"
  end

  def test_recipe(opts \\ []) do
    defaults = [
      origin: nil,
      body: nil,
      random_content: nil,
      headers: %{},
      stages: [],
      route: "/*"
    ]

    struct(Recipe, Keyword.merge(defaults, opts))
  end
end
