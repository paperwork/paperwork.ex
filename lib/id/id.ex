
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

    def from_gid(gid) when is_binary(gid) do
        {:ok, config_system_id} = Paperwork.Internal.Request.config("system_id")

        resource_gid = String.split(gid, "@")
        resource_id =
            resource_gid
            |> Enum.at(0)
        resource_system_id =
            resource_gid
            |> Enum.at(1,
                config_system_id
                |> Map.get("value")
            )

        %__MODULE__{
            gid: gid,
            id: resource_id,
            system_id: resource_system_id
        }
    end
end

