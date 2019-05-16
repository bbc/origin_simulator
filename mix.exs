defmodule OriginSimulator.MixProject do
  use Mix.Project

  def project do
    [
      app: :origin_simulator,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OriginSimulator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7.1"},
      {:cowboy, "~> 2.4"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.5"},
      {:distillery, "~> 2.0", runtime: false},
    ]
  end
end
