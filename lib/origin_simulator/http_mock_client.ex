defmodule OriginSimulator.HTTPMockClient do
  def get(_endpoint) do
    {:ok, %HTTPoison.Response{body: "some content from origin" }}
  end
end
