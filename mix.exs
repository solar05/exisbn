defmodule Exisbn.MixProject do
  use Mix.Project

  def project do
    [
      app: :exisbn,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "Exisbn",
      deps: deps(),
      source_url: "https://github.com/solar05/exisbn"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "ISBN utility library for Elixir."
  end

  defp package() do
    [
      name: "exisbn",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/solar05/exisbn"}
    ]
  end
end
