defmodule Mix.Tasks.UploadRecipe do
  @moduledoc """
  A mix task for uploading JSON recipes in the `examples` directory to OriginSimulator.

  ```
  # upload `examples/demo.json` to OriginSimulator running locally (http://localhost:8080).
  mix upload_recipe demo

  # upload `examples/demo.json to OriginSimulator on a specific host.
  mix upload_recipe "http://origin-simulator.com" demo
  ```
  """

  use Mix.Task

  @spec run(list()) :: {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()} | {:error, HTTPoison.Error.t()}
  def run([host, recipe]) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    recipe = get_json("./examples/#{recipe}.json")

    HTTPoison.post("#{host}/_admin/add_recipe", recipe)
  end

  def run([recipe]) do
    run(["http://localhost:8080", recipe])
  end

  defp get_json(filename) do
    File.read!(filename)
  end
end
