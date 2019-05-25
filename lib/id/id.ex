
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

        # TODO: The initially provided system_id (if any) is being overwritten here.
        # This might break stuff. Think of how to implement this correctly.
        resource_system_id =
            resource_gid
            |> Enum.at(1,
                config_system_id
                |> Map.get("value"))


        %__MODULE__{
            gid: gid,
            id: resource_id,
            system_id: resource_system_id
        }
    end

    def validate_gid(gid) when is_binary(gid) do
        case Regex.match?(~r/([0-9a-f]{24}){1}@([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}){1}/, gid) do
            true -> {:ok, gid}
            false -> {:error, "Not a global ID"}
        end
    end

    def validate_gid(gid) when is_binary(gid) == false, do: {:error, "Not a global ID"}
end

