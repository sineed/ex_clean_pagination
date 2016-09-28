defmodule ExCleanPagination.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [
      app: :ex_clean_pagination,
      version: @version,
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: description,
      package: package
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp description do
    """
    API pagination the way RFC7233 intended it
    """
  end

  defp package do
    [
      maintainers: ["Denis Tataurov"],
      files: [
        "lib/ex_clean_pagination.ex",
        "lib/ex_clean_pagination",
        "mix.exs",
        "README.md"
      ],
      licenses: ["MIT"],
      links: %{github: "https://github.com/sineed/ex_clean_pagination"}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.2.0"},
      {:ex_doc, "~> 0.13", only: :dev}
    ]
  end
end
