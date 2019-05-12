defmodule Paperwork.Internal.Request do
    require Logger

    def entity_from_response(url, %Mojito.Response{body: body, status_code: 200, headers: headers} = _response) when is_binary(url) and is_binary(body) and is_list(headers) do
        entity = Jason.decode!(body) |> Map.get("content")
        Cachex.put!(:paperwork_resources, url, entity, ttl: :timer.seconds(Confex.fetch_env!(:paperwork, :internal)[:cache_ttl]))
        {:ok, entity}
    end

    def entity_from_response(url, %Mojito.Response{body: body, status_code: status_code, headers: headers} = response) when is_binary(url) and is_binary(body) and is_integer(status_code) and is_list(headers) do
        {:error, response}
    end

    def request_get(url) when is_binary(url) do
        case Mojito.request(:get, url) do
            {:ok, response} -> url |> entity_from_response(response)
            other -> {:error, other}
        end
    end

    def request_get_cached(url) when is_binary(url) do
        case Cachex.get(:paperwork_resources, url) do
            {:ok, nil} ->
                Logger.debug("No cached result for #{url}: nil")
                request_get(url)
            {:ok, entity} ->
                Logger.debug("Returning cached result for #{url}")
                {:ok, entity}
            other ->
                Logger.debug("No cached result for #{url}: #{inspect other}")
                request_get(url)
        end
    end

    def user(user_id) when is_binary(user_id) do
        user(user_id, true)
    end

    def user(user_id, true=_cached) when is_binary(user_id) do
        url = "#{Paperwork.Internal.Resource.users()}/#{user_id}"
        request_get_cached(url)
    end

    def user(user_id, false=_cached) when is_binary(user_id) do
        url = "#{Paperwork.Internal.Resource.users()}/#{user_id}"
        request_get(url)
    end

    def user!(user_id, cached \\ true) when is_binary(user_id) do
        case user(user_id, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end

    def config(config_id) when is_binary(config_id) do
        config(config_id, true)
    end

    def config(config_id, true=_cached) when is_binary(config_id) do
        url = "#{Paperwork.Internal.Resource.configs()}/#{config_id}"
        request_get_cached(url)
    end

    def config(config_id, false=_cached) when is_binary(config_id) do
        url = "#{Paperwork.Internal.Resource.configs()}/#{config_id}"
        request_get(url)
    end

    def config!(config_id, cached \\ true) when is_binary(config_id) do
        case config(config_id, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end
end
