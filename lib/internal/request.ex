defmodule Paperwork.Internal.Request do
    require Logger

    def get_caching_id(url, params) when is_binary(url) and is_map(params), do: url <> Enum.map_join(params, "_", fn {key, val} -> "#{key}_#{val}" end)

    def entity_from_response(url, params, %Mojito.Response{body: body, status_code: 200, headers: headers} = _response) when is_binary(url) and is_map(params) and is_binary(body) and is_list(headers) do
        entity = Jason.decode!(body) |> Map.get("content")
        caching_id = get_caching_id(url, params)

        Cachex.put!(:paperwork_resources, caching_id, entity, ttl: :timer.seconds(Confex.fetch_env!(:paperwork, :internal)[:cache_ttl]))
        {:ok, entity}
    end

    def entity_from_response(url, params, %Mojito.Response{body: body, status_code: 404, headers: headers} = _response) when is_binary(url) and is_map(params) and is_binary(body) and is_list(headers) do
        entity = Jason.decode!(body) |> Map.get("content")
        {:notfound, entity}
    end

    def entity_from_response(url, params, %Mojito.Response{body: body, status_code: status_code, headers: headers} = response) when is_binary(url) and is_map(params) and is_binary(body) and is_integer(status_code) and is_list(headers) do
        {:error, response}
    end

    def request_get(url, params \\ %{}) when is_binary(url) and is_map(params) do
        url_with_query = url <> "?" <> URI.encode_query(params)

        case Mojito.request(:get, url_with_query) do
            {:ok, response} -> url |> entity_from_response(params, response)
            other -> {:error, other}
        end
    end

    def request_get_cached(url, params \\ %{}) when is_binary(url) and is_map(params) do
        caching_id = get_caching_id(url, params)

        case Cachex.get(:paperwork_resources, caching_id) do
            {:ok, nil} ->
                Logger.debug("No cached result for #{caching_id}: nil")
                request_get(url, params)
            {:ok, entity} ->
                Logger.debug("Returning cached result for #{caching_id}")
                {:ok, entity}
            other ->
                Logger.debug("No cached result for #{caching_id}: #{inspect other}")
                request_get(url, params)
        end
    end

    # ╔════════════════════════════════════════════════════════════════════════════╗
    # ║ Config                                                                     ║
    # ╚════════════════════════════════════════════════════════════════════════════╝

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

    # ╔════════════════════════════════════════════════════════════════════════════╗
    # ║ User                                                                       ║
    # ╚════════════════════════════════════════════════════════════════════════════╝

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

    # ╔════════════════════════════════════════════════════════════════════════════╗
    # ║ Note                                                                       ║
    # ╚════════════════════════════════════════════════════════════════════════════╝

    def note(note_id) when is_binary(note_id) do
        note(note_id, true)
    end

    def note(note_id, true=_cached) when is_binary(note_id) do
        url = "#{Paperwork.Internal.Resource.notes()}/#{note_id}"
        request_get_cached(url)
    end

    def note(note_id, false=_cached) when is_binary(note_id) do
        url = "#{Paperwork.Internal.Resource.notes()}/#{note_id}"
        request_get(url)
    end

    def note!(note_id, cached \\ true) when is_binary(note_id) do
        case note(note_id, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end

    # ╔════════════════════════════════════════════════════════════════════════════╗
    # ║ Attachment                                                                 ║
    # ╚════════════════════════════════════════════════════════════════════════════╝

    def attachment(attachment_id) when is_binary(attachment_id) do
        attachment(attachment_id, true)
    end

    def attachment(attachment_id, true=_cached) when is_binary(attachment_id) do
        url = "#{Paperwork.Internal.Resource.attachments()}/#{attachment_id}"
        request_get_cached(url)
    end

    def attachment(attachment_id, false=_cached) when is_binary(attachment_id) do
        url = "#{Paperwork.Internal.Resource.attachments()}/#{attachment_id}"
        request_get(url)
    end

    def attachment!(attachment_id, cached \\ true) when is_binary(attachment_id) do
        case attachment(attachment_id, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end

    # ╔════════════════════════════════════════════════════════════════════════════╗
    # ║ Journal                                                                    ║
    # ╚════════════════════════════════════════════════════════════════════════════╝

    def journal(journal_id) when is_binary(journal_id) do
        journal(journal_id, true)
    end

    def journal(journal_id, true=_cached) when is_binary(journal_id) do
        url = "#{Paperwork.Internal.Resource.journals()}/#{journal_id}"
        request_get_cached(url)
    end

    def journal(journal_id, false=_cached) when is_binary(journal_id) do
        url = "#{Paperwork.Internal.Resource.journals()}/#{journal_id}"
        request_get(url)
    end

    def journal!(journal_id, cached \\ true) when is_binary(journal_id) do
        case journal(journal_id, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end

    def journals(params \\ %{}) when is_map(params) do
        journals(params, true)
    end

    def journals(params, true=_cached) when is_map(params) do
        url = "#{Paperwork.Internal.Resource.journals()}"
        request_get_cached(url, params)
    end

    def journals(params, false=_cached) when is_map(params) do
        url = "#{Paperwork.Internal.Resource.journals()}"
        request_get(url, params)
    end

    def journals!(params, cached \\ true) when is_map(params) do
        case journals(params, cached) do
            {:ok, response} -> response
            _ -> nil
        end
    end

end
