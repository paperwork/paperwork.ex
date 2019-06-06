defmodule Paperwork.Events.Consumer do
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

    def handle_info(:connect, conn) do
        amqp_url =
            Paperwork.Helpers.Event.events_url()

        case AMQP.Connection.open(amqp_url) do
            {:ok, conn} ->
                Logger.debug("Successfully connected to events stream on #{amqp_url}! Setting up exchanges & queues ...")
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
                Paperwork.Helpers.Event.events_dead_letter_queue(), durable: true
            )

        :ok =
            chan
            |> AMQP.Exchange.direct(Paperwork.Helpers.Event.events_dead_letter_exchange(), durable: true)

        :ok =
            chan
            |> AMQP.Queue.bind(Paperwork.Helpers.Event.events_dead_letter_queue(), Paperwork.Helpers.Event.events_dead_letter_exchange())

        {:ok, _} =
            chan
            |> AMQP.Queue.declare(
                Paperwork.Helpers.Event.events_queue(),
                durable: true,
                arguments: [
                    {"x-dead-letter-exchange", :longstr, Paperwork.Helpers.Event.events_dead_letter_exchange()},
                    {"x-dead-letter-routing-key", :longstr, Paperwork.Helpers.Event.events_dead_letter_queue()}
                ]
            )

        :ok =
            chan
            |> AMQP.Exchange.direct(Paperwork.Helpers.Event.events_exchange(), durable: true)

        :ok =
            chan
            |> AMQP.Queue.bind(Paperwork.Helpers.Event.events_queue(), Paperwork.Helpers.Event.events_exchange())

        :ok =
            chan
            |> AMQP.Basic.qos(prefetch_count: 10)

        {:ok, _consumer_tag} =
            chan
            |> AMQP.Basic.consume(Paperwork.Helpers.Event.events_queue())

        {:ok, chan}
    end

    def consume(channel, tag, redelivered, payload) do
        case Paperwork.Helpers.Event.events_consumer().consume(payload, tag, redelivered) do
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
