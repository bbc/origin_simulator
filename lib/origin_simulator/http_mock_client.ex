defmodule OriginSimulator.HTTPMockClient do
  def get(endpoint, type: :html), do: get(endpoint)
  def get(_endpoint, type: :json), do: {:ok, %HTTPoison.Response{body: "{\"hello\":\"world\"}"}}
  def get(_endpoint), do: {:ok, %HTTPoison.Response{body: "some content from origin"}}
end
