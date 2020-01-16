defmodule Nicene.MixProject do
  use Mix.Project

  @github_url "https://github.com/sketch_hq/nicene"

  def project do
    [
      app: :nicene,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: false,
      description: "A Credo plugin containing additional checks.",
      deps: deps(),
      package: package(),

      # Docs
      name: "Nicene",
      docs: [
        main: "Readme",
        extras: ["README.md"],
        source_url: @github_url
      ]
    ]
  end

  def application(), do: []

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      files: [
        "priv",
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Devon Estes"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp deps() do
    [
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
