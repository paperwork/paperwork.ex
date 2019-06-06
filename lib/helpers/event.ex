defmodule Paperwork.Helpers.Event do
    require Logger

    def events_url, do: Confex.fetch_env!(:paperwork, :events)[:url]
    def events_reconnect_interval, do: Confex.fetch_env!(:paperwork, :events)[:reconnect_interval]

    def events_exchange, do: Confex.fetch_env!(:paperwork, :events)[:exchange]
    def events_queue, do: Confex.fetch_env!(:paperwork, :events)[:queue]

    def events_dead_letter_exchange, do: Confex.fetch_env!(:paperwork, :events)[:dead_letter_exchange]
    def events_dead_letter_queue, do: Confex.fetch_env!(:paperwork, :events)[:dead_letter_queue]

    def events_consumer, do: Confex.fetch_env!(:paperwork, :events)[:handler]
end
