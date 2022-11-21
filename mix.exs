defmodule SwaggerUiPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :swagger_ui_plug,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, ">= 0.0.0"}
    ]
  end
end
