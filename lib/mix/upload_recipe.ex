defmodule Mix.Tasks.UploadRecipe do
  use Mix.Task

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
