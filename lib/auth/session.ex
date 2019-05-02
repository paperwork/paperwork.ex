defmodule Paperwork.Auth.Session do
    require Logger
    use Joken.Config

    def get(%Plug.Conn{}=conn) do
        conn.private[:paperwork_user]
    end

    def get_global_id(%Plug.Conn{}=conn) do
        user_id = get_user_id(conn)
        system_id = get_system_id(conn)
        construct_global_id(user_id, system_id)
    end

    def get_user_id(%Plug.Conn{}=conn) do
        conn.private[:paperwork_user] |> Map.get(:id)
    end

    def get_user_role(%Plug.Conn{}=conn) do
        conn.private[:paperwork_user] |> Map.get(:role)
    end

    def get_system_id(%Plug.Conn{}=conn) do
        conn.private[:paperwork_user] |> Map.get(:system_id)
    end

    def construct_global_id(user_id, system_id) when is_binary(user_id) and is_binary(system_id) do
        "#{user_id}@#{system_id}"
    end

    def construct_global_id(user_id, system_id) when is_nil(user_id) or is_nil(system_id) do
        nil
    end

    def token_config, do: default_claims(default_exp: 60 * 60, iss: "Paperwork", aud: "paperwork-client")

    def create(%{id: id} = user) when is_map(user) do
        signer = Joken.Signer.parse_config(:hs512)
        with \
            {:ok, %{"id" => _id, "key" => "system_id", "value" => system_id}} <- Paperwork.Internal.Request.config("system_id"),
            {:ok, claims} <- Joken.generate_claims(token_config(), %{"sub" => BSON.ObjectId.encode!(id), "typ" => "access", "aud" => system_id}),
            {:ok, jwt, claims} <- Joken.encode_and_sign(claims, signer) do
                {:ok, jwt, claims}
        else
            err ->
                Logger.error("Session could not be retrieved: #{inspect err}")
                {:error, nil}
        end
    end
end
