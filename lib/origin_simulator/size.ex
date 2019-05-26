defmodule OriginSimulator.Size do
  def parse(size) when is_binary(size) do
    Integer.parse(size) |> parse()
  end

  def parse({size, "b"}), do: size

  def parse({size, "kb"}) do
    size * 1024
  end

  def parse({size, "mb"}) do
    size * 1024 * 1024
  end

  def parse({_, _}) do
    raise("Invalid size, please define size in b, kb or mb")
  end
end
