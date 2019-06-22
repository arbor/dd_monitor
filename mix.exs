defmodule DdMonitor.MixFile do
  use Mix.Project

  def project do
    [
      app: :dd_monitor,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  defp escript do
    [
      main_module: DdMonitor.CLI,
      path: "./releases/dd-monitor"
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
      {:httpoison, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:ddog, git: "https://github.com/lenfree/ddog.git"}
    ]
  end
end
