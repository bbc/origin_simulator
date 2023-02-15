defmodule OriginSimulator.DefaultRecipe do
  alias OriginSimulator.Recipe

  def generate do
    %{
      "headers" => %{"cache-control" => "public, max-age=30", "content-encoding" => "gzip"},
      "body" => body(),
      "stages" => [%{"status" => 200, "latency" => "100ms", "at" => 0}]
    }
    |> Poison.encode!()
    |> Recipe.parse()
  end

  def body do
    File.read!(File.cwd!() <> "/examples/default.html")
  end
end
