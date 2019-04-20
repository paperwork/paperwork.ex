defmodule Paperwork do
    import Plug
    use Paperwork.Server
    use Paperwork.Helpers.Response

    defmacro __using__(_) do
        quote do
            before do
                plug Plug.Logger
                plug Corsica, origins: "*"
                plug Plug.Parsers,
                    pass: ["*/*"],
                    json_decoder: Jason,
                    parsers: [:urlencoded, :json, :multipart]
            end

            resources do
                get do
                    json(conn, %{hello: :paperworkex})
                end
            end

            rescue_from Unauthorized, as: e do
                conn
                |> resp({:unauthorized, %{status: 1, content: %{message: e.message}}})
            end

            rescue_from [MatchError, RuntimeError], as: e do
                IO.inspect e

                conn
                |> resp({:error, %{status: 1, content: e}})
            end

            rescue_from Maru.Exceptions.InvalidFormat, as: e do
                IO.inspect e

                conn
                |> resp({:badrequest, %{status: 1, content: %{param: e.param, reason: e.reason}}})
            end

            rescue_from Maru.Exceptions.NotFound, as: e do
                IO.inspect e

                conn
                |> resp({:notfound, %{status: 1, content: %{method: e.method, route: e.path_info}}})
            end

            rescue_from :all, as: e do
                IO.inspect e

                conn
                |> resp({:error, %{status: 1, content: e}})
            end
        end
    end
end
