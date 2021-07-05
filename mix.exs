defmodule Flexflow.MixProject do
  use Mix.Project

  @version String.trim(File.read!("VERSION"))
  @github_url "https://github.com/clszzyh/flexflow"
  @description "Lightweight and Flexible Workflow Engine."

  def project do
    [
      app: :flexflow,
      version: @version,
      description: @description,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [ci: :test],
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: true,
      package: [
        licenses: ["MIT"],
        files: ["lib", ".formatter.exs", "mix.exs", "README*", "CHANGELOG*", "VERSION"],
        exclude_patterns: ["priv/plts", ".DS_Store"],
        links: %{"GitHub" => @github_url, "Changelog" => @github_url <> "/blob/main/CHANGELOG.md"}
      ],
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_add_deps: :app_tree,
        plt_add_apps: [:ex_unit, :mix],
        list_unused_filters: true,
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: dialyzer_flags()
      ],
      docs: [
        source_ref: "v" <> @version,
        source_url: @github_url,
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:prod), do: ~w(lib)
  defp elixirc_paths(_), do: ~w(lib test/support)

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Flexflow.Application, []},
      extra_applications: [:logger]
    ]
  end

  # http://erlang.org/doc/man/dialyzer.html#gui-1
  defp dialyzer_flags do
    [
      :error_handling,
      :race_conditions,
      :underspecs,
      :unknown,
      :unmatched_returns
      # :overspecs
      # :specdiffs
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:earmark_parser, "~> 1.4", runtime: false},
      {:ex_doc, "~> 0.22", runtime: false},
      {:yamerl, "~> 0.8.0"},
      {:telemetry, "~> 1.0.0"}
    ]
  end

  defp aliases do
    [
      cloc: "cmd cloc --exclude-dir=_build,deps,doc .",
      ci: [
        "compile --warnings-as-errors --force --verbose",
        "format --check-formatted",
        "credo --strict",
        "docs",
        "dialyzer",
        "test"
      ]
    ]
  end
end
