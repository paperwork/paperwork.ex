defmodule Paperwork.MixProject do
    use Mix.Project

    def project do
        [
            app: :paperwork,
            version: "0.1.0",
            elixir: "~> 1.8",
            start_permanent: Mix.env() == :prod,
            deps: deps()
        ]
    end

    def application do
        [
            extra_applications: [:confex, :cachex, :logger]
        ]
    end

    defp deps do
        [
            {:confex, "~> 3.4"},
            {:maru, "~> 0.14.0-pre.1"},
            {:plug_cowboy, "~> 2.0"},
            {:jason, "~> 1.1"},
            {:corsica, "~> 1.1"},
            {:mongodb, "~> 0.4.7"},
            {:poolboy, "~> 1.5"},
            {:bcrypt_elixir, "~> 2.0"},
            {:joken, "~> 2.0"},
            {:mojito, "~> 0.3.0"},
            {:amqp, "~> 1.2"},
            {:exsync, "~> 0.2", only: :dev},
            {:cachex, "~> 3.1"}
        ]
    end
end
