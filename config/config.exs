use Mix.Config

config :paperwork, :server,
    app: :paperwork,
    cache_ttl_default: 86_400,
    cache_janitor_interval: 60

config :paperwork, :internal,
    cache_ttl: 60,
    configs:     {:system, :string, "INTERNAL_RESOURCE_CONFIGS",     "http://localhost:8880/internal/configs"},
    users:       {:system, :string, "INTERNAL_RESOURCE_USERS",       "http://localhost:8881/internal/users"},
    notes:       {:system, :string, "INTERNAL_RESOURCE_NOTES",       "http://localhost:8882/internal/notes"},
    attachments: {:system, :string, "INTERNAL_RESOURCE_ATTACHMENTS", "http://localhost:8883/internal/attachments"},
    journals:    {:system, :string, "INTERNAL_RESOURCE_JOURNALS",    "http://localhost:8884/internal/journals"}

config :paperwork, :events,
    url: {:system, :string, "EVENTS_URL", "amqp://localhost"},
    reconnect_interval: {:system, :integer, "EVENTS_RECONNECT_INTERVAL", 10_000},
    exchange: {:system, :string, "EVENTS_EXCHANGE", "tests_exchange"},
    queue: {:system, :string, "EVENTS_QUEUE", "tests_queue"},
    dead_letter_exchange: {:system, :string, "EVENTS_DEAD_LETTER_EXCHANGE", "tests_dead_letter_exchange"},
    dead_letter_queue: {:system, :string, "EVENTS_DEAD_LETTER_QUEUE", "tests_dead_letter_queue"},
    handler: nil

config :logger,
    backends: [:console]
