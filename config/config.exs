use Mix.Config

config :paperwork, :server,
    app: :paperwork,
    cache_ttl_default: 86_400,
    cache_janitor_interval: 60

config :paperwork, :internal,
    cache_ttl: 60,
    configs:  {:system, :string, "INTERNAL_RESOURCE_CONFIGS",  "http://localhost:8880/internal/configs"},
    users:    {:system, :string, "INTERNAL_RESOURCE_USERS",    "http://localhost:8881/internal/users"},
    notes:    {:system, :string, "INTERNAL_RESOURCE_NOTES",    "http://localhost:8882/internal/notes"},
    storages: {:system, :string, "INTERNAL_RESOURCE_STORAGES", "http://localhost:8883/internal/storages"}

config :logger,
    backends: [:console]
