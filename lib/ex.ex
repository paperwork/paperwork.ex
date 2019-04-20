defmodule Paperwork.Ex do
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts)
    end

    def init(_opts) do
        case Code.ensure_loaded(ExSync) do
            {:module, ExSync = mod} ->
                mod.start()
            {:error, :nofile} ->
                :ok
        end

        children = [
            worker(Cachex, [:paperwork_resources, []])
        ]

        Supervisor.init(children, strategy: :one_for_one, name: Paperwork.Ex.Supervisor)
    end
end
