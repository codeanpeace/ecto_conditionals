defmodule EctoConditionals.Mixfile do
  use Mix.Project

  def project do
    [app: :ecto_conditionals,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :ecto]]
  end

  defp description do
    """
    EctoConditionals implements a flexibly functional find_or_create and upsert behavior for Ecto models.
    """
  end

  defp package do
    [
      maintainers: ["h@rrison.us"],
      licenses: ["GPL 3.0"],
      links: %{"GitHub" => "https://github.com/codeanpeace/ecto_conditionals"}
    ]
  end

  defp deps do
    [{:ecto, ">= 0.0.0"}]
  end
end
