defmodule ExCleanPagination.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :ex_clean_pagination,
      version: @version,
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def package do
    [
      maintainers: ["Denis Tataurov"],
      files: [
        "lib/ex_clean_pagination.ex",
        "lib/ex_clean_pagination",
        "mix.exs",
        "README.md",
        "LICENSE*"
      ],
      licenses: ["MIT"],
      links: %{github: "https://github.com/sineed/ex_clean_pagination"}
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:plug, "~> 1.2.0"}]
  end
end
