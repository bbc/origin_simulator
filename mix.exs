defmodule OriginSimulator.MixProject do
  use Mix.Project

  @description """
  A tool to simulate a (flaky) upstream origin during load and stress tests.
  """

  def project do
    [
      app: :origin_simulator,
      version: "1.0.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "OriginSimulator",
      description: @description,
      source_url: "https://github.com/bbc/origin_simulator",
      homepage_url: "https://github.com/bbc/origin_simulator",
      docs: [
        main: "README",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {OriginSimulator.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.7.1"},
      {:cowboy, "~> 2.4"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.5"},
      {:distillery, "~> 2.0", runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "origin_simulator",
      maintainers: [
        "bbc",
        "JoeARO",
        "woodyblah",
        "james-bowers",
        "ettomatic",
        "samfrench",
        "chrishop",
        "astalker",
        "boonious"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bbc/origin_simulator"}
    ]
  end
end
