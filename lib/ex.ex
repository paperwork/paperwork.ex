defmodule Paperwork.Ex do
    use Supervisor
    import Cachex.Spec

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts)
    end

    def init(_opts) do
        case Code.ensure_loaded(ExSync) do
            {:module, ExSync = mod} ->
                mod.start()
            {:error, _} ->
                :ok
        end

        children = [
            worker(Cachex, [
                :paperwork_resources,
                [
                    expiration: expiration(
                        default: :timer.seconds(Confex.fetch_env!(:paperwork, :server)[:cache_ttl_default]),
                        interval: :timer.seconds(Confex.fetch_env!(:paperwork, :server)[:cache_janitor_interval]),
                        lazy: false
                    )
                ]
            ])
        ]

        Supervisor.init(children, strategy: :one_for_one, name: Paperwork.Ex.Supervisor)
    end
end
