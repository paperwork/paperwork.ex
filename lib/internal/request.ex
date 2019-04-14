defmodule Paperwork.Internal.Request do
    def entity_from_response(%Mojito.Response{body: body, status_code: status_code, headers: headers} = response) when is_binary(body) and is_integer(status_code) and is_list(headers) do
        case status_code do
            200 -> {:ok, Jason.decode!(body) |> Map.get("content")}
            other -> {:error, response}
        end
    end

    def user(user_id) when is_binary(user_id) do
        case Mojito.request(:get, "#{Paperwork.Internal.Resource.users()}/#{user_id}") do
            {:ok, response} -> entity_from_response(response)
            other -> {:error, other}
        end
    end

    def config(config_id) when is_binary(config_id) do
        case Mojito.request(:get, "#{Paperwork.Internal.Resource.configs()}/#{config_id}") do
            {:ok, response} -> entity_from_response(response)
            other -> {:error, other}
        end
    end
end
