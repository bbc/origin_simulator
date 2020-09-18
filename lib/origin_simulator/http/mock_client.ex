defmodule OriginSimulator.HTTPMockClient do
  def get(_endpoint, headers \\ %{})

  def get(endpoint, type: :html), do: get(endpoint)
  def get(_endpoint, type: :json), do: {:ok, %HTTPoison.Response{body: "{\"hello\":\"world\"}"}}

  def get(_endpoint, %{"content-encoding" => "gzip"}), do: {:ok, %HTTPoison.Response{body: :zlib.gzip("some content from origin")}}
  def get(_endpoint, _headers), do: {:ok, %HTTPoison.Response{body: "some content from origin"}}
end
