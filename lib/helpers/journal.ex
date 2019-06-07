defmodule Paperwork.Helpers.Journal do
    require Logger

    def api_response_to_journal(response, params, action, resource, trigger, global_id) do
        case response do
            {:ok, content} ->
                Logger.debug("Sending journal event ...")

                resource_id =
                    cond do
                        is_binary(content.id) == true -> content.id
                        is_map(content.id) == true -> content.id |> BSON.ObjectId.encode!()
                        true -> raise "Not a valid resource id!"
                    end

                params
                |> Paperwork.Helpers.Journal.journal_entry_payload(action, resource, Paperwork.Id.from_gid(resource_id), trigger, Paperwork.Id.from_gid(global_id))
                |> Paperwork.Events.Publisher.publish(Paperwork.Helpers.Event.events_exchange(), "")
            _ ->
                Logger.debug("Not sending journal event.")
        end

        response
    end

    def journal_entry_payload(content, action, resource, %Paperwork.Id{} = resource_gid, trigger, %Paperwork.Id{} = trigger_gid) do
        trigger_id = trigger_gid.id
        trigger_system_id = trigger_gid.system_id

        resource_id = resource_gid.id
        resource_system_id = resource_gid.system_id

        %{
            trigger: trigger |> validate_trigger!(),
            trigger_id: trigger_id |> validate_trigger_id!(),
            trigger_system_id: trigger_system_id |> validate_trigger_system_id!(),
            action: action |> validate_action!(),
            resource: resource |> validate_resource!(),
            resource_id: resource_id |> validate_resource_id!(),
            resource_system_id: resource_system_id |> validate_resource_system_id!(),
            content: content |> validate_content!() |> Paperwork.Helpers.Map.unstruct!()
        }
    end

    def validate_trigger!(trigger) when is_binary(trigger) do
        case trigger do
            "user" -> trigger
            _ -> raise "Not a valid trigger"
        end
    end

    def validate_trigger!(trigger) when is_atom(trigger) do
        Atom.to_string(trigger)
        |> validate_trigger!()
    end

    def validate_trigger!(trigger) when not is_binary(trigger) and not is_atom(trigger) do
        raise "Not a valid trigger"
    end


    def validate_trigger_id!(trigger_id) when is_binary(trigger_id) do
        trigger_id
    end

    def validate_trigger_id!(trigger_id) when not is_binary(trigger_id) do
       raise "Not a valid trigger_id"
    end


    def validate_trigger_system_id!(trigger_system_id) when is_binary(trigger_system_id) do
        trigger_system_id
    end

    def validate_trigger_system_id!(trigger_system_id) when not is_binary(trigger_system_id) do
       raise "Not a valid trigger_system_id"
    end


    def validate_action!(action) when is_binary(action) do
        case action do
            "create" -> action
            "update" -> action
            "delete" -> action
            _ -> raise "Not a valid action"
        end
    end

    def validate_action!(action) when is_atom(action) do
        Atom.to_string(action)
        |> validate_action!()
    end

    def validate_action!(action) when not is_binary(action) and not is_atom(action) do
        raise "Not a valid action"
    end


    def validate_resource!(resource) when is_binary(resource) do
        case resource do
            "config" -> resource
            "user" -> resource
            "note" -> resource
            "attachment" -> resource
            _ -> raise "Not a valid resource"
        end
    end

    def validate_resource!(resource) when is_atom(resource) do
        Atom.to_string(resource)
        |> validate_resource!()
    end

    def validate_resource!(resource) when not is_binary(resource) and not is_atom(resource) do
        raise "Not a valid resource"
    end

    def validate_resource_id!(resource_id) when is_binary(resource_id) do
        resource_id
    end

    def validate_resource_id!(resource_id) when not is_binary(resource_id) do
       raise "Not a valid resource_id"
    end


    def validate_resource_system_id!(resource_system_id) when is_binary(resource_system_id) do
        resource_system_id
    end

    def validate_resource_system_id!(resource_system_id) when not is_binary(resource_system_id) do
       raise "Not a valid resource_system_id"
    end


    def validate_content!(content) when is_map(content) do
        content
    end

    def validate_content!(content) when not is_map(content) do
        raise "Not a valid content"
    end

end
