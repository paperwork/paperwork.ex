defmodule Paperwork.Events.Publisher do
    use GenServer
    require Logger

    def events_url, do: Confex.fetch_env!(:paperwork, :events)[:url]
    def events_reconnect_interval, do: Confex.fetch_env!(:paperwork, :events)[:reconnect_interval]

    def start_link(opts \\ [name: __MODULE__]) do
        GenServer.start_link(__MODULE__, nil, opts)
    end

    def init(_) do
        send(self(), :connect)
        {:ok, nil}
    end

    def get_connection do
        case GenServer.call(__MODULE__, :get) do
            nil -> {:error, :not_connected}
            conn -> {:ok, conn}
        end
    end

    def handle_call(:get, _, conn) do
        {:reply, conn, conn}
    end

    def handle_info(:connect, _conn) do
        amqp_url =
            events_url()

        case AMQP.Connection.open(amqp_url) do
            {:ok, conn} ->
                Logger.debug("Successfully connected to events stream on #{amqp_url}!")
                {:ok, chan} = setup(conn)
                Process.monitor(conn.pid)
                {:noreply, chan}

            {:error, _} ->
                Logger.error("Failed to connect to events stream on #{amqp_url}. Reconnecting soon ...")
                Process.send_after(self(), :connect, events_reconnect_interval())
                {:noreply, nil}
        end
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        Logger.error("Lost connection to events stream!")
        {:stop, {:connection_lost, reason}, nil}
    end

    def handle_call({:publish, exchange, routing_key, payload}, channel) do
        Logger.debug("Publishing event to #{inspect exchange} / #{inspect routing_key} ...")

        payload_string =
            Jason.encode!(payload)
            |> IO.inspect

        :ok =
            channel
            |> AMQP.Basic.publish(exchange, routing_key, payload_string, [persistent: false])

        {:reply, :ok, channel}
    rescue
        exception ->
            Logger.error("#{inspect exception}")
            {:reply, :error, channel}
    end

    defp setup(conn) do
        conn
        |> AMQP.Channel.open()
    end

    def publish(exchange, routing_key, payload) when is_binary(exchange) and is_binary(routing_key) and is_map(payload) do
        GenServer.call(__MODULE__, {:publish, exchange, routing_key, payload})
    end
end
