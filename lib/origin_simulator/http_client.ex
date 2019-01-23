defmodule OriginSimulator.HTTPClient do
  def get(_endpoint, :test) do
    {:ok,  %HTTPoison.Response{body: "some content from origin"}}
  end

  def get(endpoint, _env) do
    headers = []
    options = [recv_timeout: 3000]

    HTTPoison.get(endpoint, headers, options)
  end
end
