defmodule Paperwork.Events.Publisher do
    use GenServer
    require Logger

    def start_link(args) do
        GenServer.start_link __MODULE__, args, name: __MODULE__
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
            Paperwork.Helpers.Event.events_url()

        case AMQP.Connection.open(amqp_url) do
            {:ok, conn} ->
                Logger.debug("Successfully connected to events stream on #{amqp_url}!")
                {:ok, chan} = setup(conn)
                Process.monitor(conn.pid)
                {:noreply, chan}

            {:error, _} ->
                Logger.error("Failed to connect to events stream on #{amqp_url}. Reconnecting soon ...")
                Process.send_after(self(), :connect, Paperwork.Helpers.Event.events_reconnect_interval())
                {:noreply, nil}
        end
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        Logger.error("Lost connection to events stream!")
        {:stop, {:connection_lost, reason}, nil}
    end

    def handle_cast({:publish, exchange, routing_key, payload}, channel) do
        Logger.debug("Publishing event to #{inspect exchange} / #{inspect routing_key} in channel #{inspect channel} ...")

        payload_string =
            Jason.encode!(payload)

        :ok =
            channel
            |> AMQP.Basic.publish(exchange, routing_key, payload_string, [persistent: false])

        AMQP.Confirm.wait_for_confirms(channel, 60)

        Logger.debug("Published payload #{inspect payload_string}!")

        {:noreply, channel}
    rescue
        exception ->
            Logger.error("#{inspect exception}")
            {:noreply, channel}
    end

    defp setup(conn) do
        {:ok, chan} =
            conn
            |> AMQP.Channel.open()

        :ok =
            chan
            |> AMQP.Confirm.select()

        {:ok, chan}
    end

    def publish(payload, exchange, routing_key) when is_map(payload) and is_binary(exchange) and is_binary(routing_key) do
        GenServer.cast(__MODULE__, {:publish, exchange, routing_key, payload})
    end
end
