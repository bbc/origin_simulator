defmodule OriginSimulator.Duration do
  def parse(0), do: 0

  def parse(time) when is_integer(time) do
    raise("Invalid stage latency, please define time in s or ms")
  end

  def parse(time) when is_binary(time) do
    cond do
      String.contains?(time, "..") -> String.split(time, "..")
      true -> Integer.parse(time)
    end
    |> parse()
  end

  def parse({time, "ms"}), do: time

  def parse({time, "s"}), do: time * 1000

  def parse({0, _}), do: 0

  def parse(times) when is_list(times) do
    min_max = Enum.map(times, fn (t) -> parse(t) end)
    apply(Range, :new, min_max)
  end
end
