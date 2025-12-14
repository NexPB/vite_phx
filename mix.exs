defmodule Vite.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :vite_phx,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def cli do
    [preferred_envs: [docs: :docs]]
  end

  defp package do
    [
      maintainers: ["Roman Heinrich", "NexPB"],
      description: "vite_phx helps to integrate Vite.js into your Phoenix app",
      licenses: ["MIT"],
      links: %{Github: "https://github.com/NexPB/vite_phx"},
      files: ~w(lib CHANGELOG.md LICENSE.md mix.exs README.md .formatter.exs)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:igniter, "~> 0.7", optional: true}
    ]
  end

  def docs() do
    [
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      formatters: ["html", "epub"],
      extras: extras()
    ]
  end

  def extras do
    [
      "guides/introduction.md",
      "guides/setup.md",
      "guides/faq.md"
    ]
  end
end
