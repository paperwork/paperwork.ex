
defmodule Paperwork.Id do
    require Logger

    @type t :: %__MODULE__{
        gid: String.t(),
        id: String.t(),
        system_id: String.t()
    }
    defstruct \
        gid: "",
        id: "",
        system_id: ""

    def split_gid(gid) when is_binary(gid), do: String.split(gid, "@")

    def from_gid(gid) when is_binary(gid) do
        {:ok, config_system_id} = Paperwork.Internal.Request.config("system_id")

        resource_gid =
            gid
            |> split_gid()

        resource_id =
            resource_gid
            |> Enum.at(0)

        resource_system_id =
            case Enum.at(resource_gid, 1) do
                nil ->
                    config_system_id
                    |> Map.get("value")
                existing_system_id ->
                    existing_system_id
            end

        %__MODULE__{
            gid: "#{resource_id}@#{resource_system_id}",
            id: resource_id,
            system_id: resource_system_id
        }
    end

    def validate_gid(gid) when is_binary(gid) do
        case Regex.match?(~r/^([0-9a-f]{24}){1}@([0-9a-f]{24}){1}$/i, gid) do
            true -> {:ok, gid}
            false -> {:error, "Not a global ID"}
        end
    end

    def validate_gid(gid) when is_binary(gid) == false, do: {:error, "Not a global ID"}

    def string_is_objectid(id) when is_binary(id) do
        Regex.match?(~r/^([0-9a-f]{24}){1}$/i, id)
    end

    # def string_is_uuid(id) when is_binary(id) do
    #     Regex.match?(~r/^([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}){1}$/i, id)
    # end

    def maybe_id_to_objectid(id) when is_binary(id) do
        case string_is_objectid(id) do
            true ->
                id |> BSON.ObjectId.decode!()
            false ->
                id
        end
    end
end

