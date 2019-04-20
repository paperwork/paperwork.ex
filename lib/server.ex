defmodule Paperwork.Server do
    defmacro __using__(_) do
        quote do
            use Maru.Server, otp_app: Confex.fetch_env!(:paperwork, :server)[:app]

            def init(_type, opts) do
                Confex.Resolver.resolve(opts)
            end
        end
    end
end
