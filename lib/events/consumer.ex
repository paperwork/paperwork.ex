defmodule Paperwork.Events.Consumer do
    use GenServer
    require Logger

    def events_url, do: Confex.fetch_env!(:paperwork, :events)[:url]
    def events_reconnect_interval, do: Confex.fetch_env!(:paperwork, :events)[:reconnect_interval]

    def events_exchange, do: Confex.fetch_env!(:paperwork, :events)[:exchange]
    def events_queue, do: Confex.fetch_env!(:paperwork, :events)[:queue]

    def events_dead_letter_exchange, do: Confex.fetch_env!(:paperwork, :events)[:dead_letter_exchange]
    def events_dead_letter_queue, do: Confex.fetch_env!(:paperwork, :events)[:dead_letter_queue]

    def events_consumer, do: Confex.fetch_env!(:paperwork, :events)[:handler]

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

    def handle_info(:connect, conn) do
        amqp_url =
            events_url()

        case AMQP.Connection.open(amqp_url) do
            {:ok, conn} ->
                Logger.debug("Successfully connected to events stream on #{amqp_url}! Setting up exchanges & queues ...")
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

    def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
        Logger.debug("Successfully registered as event stream consumer!")
        {:noreply, chan}
    end

    def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
        Logger.error("Consumer unexpectedly cancelled! Was the queue deleted?")
        {:stop, :normal, chan}
    end

    def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
        Logger.debug("Consumer cancelled.")
        {:noreply, chan}
    end

    def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
        consume(chan, tag, redelivered, payload)
        {:noreply, chan}
    end

    defp setup(conn) do
        {:ok, chan} =
            conn
            |> AMQP.Channel.open()

        {:ok, _} =
            chan
            |> AMQP.Queue.declare(
                events_dead_letter_queue(), durable: true
            )

        :ok =
            chan
            |> AMQP.Exchange.direct(events_dead_letter_exchange(), durable: true)

        :ok =
            chan
            |> AMQP.Queue.bind(events_dead_letter_queue(), events_dead_letter_exchange())

        {:ok, _} =
            chan
            |> AMQP.Queue.declare(
                events_queue(),
                durable: true,
                arguments: [
                    {"x-dead-letter-exchange", :longstr, events_dead_letter_exchange()},
                    {"x-dead-letter-routing-key", :longstr, events_dead_letter_queue()}
                ]
            )

        :ok =
            chan
            |> AMQP.Exchange.direct(events_exchange(), durable: true)

        :ok =
            chan
            |> AMQP.Queue.bind(events_queue(), events_exchange())

        :ok =
            chan
            |> AMQP.Basic.qos(prefetch_count: 10)

        {:ok, _consumer_tag} =
            chan
            |> AMQP.Basic.consume(events_queue())

        {:ok, chan}
    end

    def consume(channel, tag, redelivered, payload) do
        case events_consumer().consume(payload, tag, redelivered) do
            {:ok, tag_return} ->
                channel
                |> AMQP.Basic.ack(tag_return)
            {:error, tag_return} ->
                channel
                |> AMQP.Basic.nack(tag_return, [requeue: false])
            {_, tag_return} ->
                channel
                |> AMQP.Basic.nack(tag_return, [requeue: true])
            _ ->
                channel
                |> AMQP.Basic.nack(tag, [requeue: true])
        end
    rescue
        exception ->
            Logger.error("#{inspect exception}")
            channel
            |> AMQP.Basic.nack(tag, [requeue: not redelivered])
    end

end
