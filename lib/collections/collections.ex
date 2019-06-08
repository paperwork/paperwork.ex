require Logger
require Jason

defimpl String.Chars, for: BSON.ObjectId do
  def to_string(object_id), do: BSON.ObjectId.encode!(object_id)
end

defimpl Jason.Encoder, for: BSON.ObjectId do
    def encode(id, options) do
        BSON.ObjectId.encode!(id) |> Jason.Encoder.encode(options)
    end
end

defmodule Paperwork.Collections do
    defmacro __using__(_opts) do
        quote do
            defimpl Jason.Encoder, for: [__MODULE__] do
              def encode(map, opts) do
                map
                |> Map.delete(:__struct__)
                |> Jason.Encode.map(opts)
              end
            end

            def fields() do
                Map.delete(%__MODULE__{}, :__struct__)
                |> Map.keys()
            end

            @spec found_or_nil(result :: Map.t) :: {:ok, %__MODULE__{}}
            defp found_or_nil(%{"_id" => _id} = result) do
                {:ok, (struct(__MODULE__, Paperwork.Collections.keys_to_atoms(result)) |> Map.put(:id, result["_id"]))}
            end

            @spec found_or_nil(result :: {:ok, Map.t}) :: {:ok, %__MODULE__{}}
            defp found_or_nil({:ok, %{"_id" => _} = result}) do
                found_or_nil(result)
            end

            @spec found_or_nil(result :: %Mongo.Cursor{}) :: {:ok, [%__MODULE__{}]}
            defp found_or_nil([%{} | _] = results) when is_list(results) do
                {:ok, (results |> Enum.map(fn model ->
                    {:ok, model_struct} = found_or_nil(model)
                    model_struct
                end)) }
            end

            @spec found_or_nil(result :: nil) :: {:notfound, nil}
            defp found_or_nil(nil = result) do
                {:notfound, nil}
            end

            @spec found_or_nil(result :: {:ok, nil}) :: {:notfound, nil}
            defp found_or_nil({:ok, nil}) do
                {:notfound, nil}
            end

            @spec found_or_nil(result :: []) :: {:notfound, nil}
            defp found_or_nil([] = result) when is_list(result) do
                {:notfound, nil}
            end

            @spec ok_or_error(result :: {:ok, %{}} | {}, id_key :: Atom.t, model :: %__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def ok_or_error(result, id_key, %__MODULE__{__struct__: _} = model) do
                case result do
                    {:ok, ok} ->
                        {:ok, Map.put(model, :id, Map.get(ok, id_key))}
                    other ->
                        Logger.error "Error: #{inspect(other)}"
                        {:error, "Internel Server Error"}
                end
            end

            @spec ok_or_error(result :: {:ok, %{}} | {}, id_key :: Atom.t, model :: %{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def ok_or_error(result, id_key, %{} = model) do
                ok_or_error(result, id_key, struct(__MODULE__, model))
            end

            @spec strip_privates({:ok, model :: %__MODULE__{}}) :: {:ok, %__MODULE__{}}
            def strip_privates({:ok, %__MODULE__{} = model}) do
                {:ok, Map.drop(model, @privates)}
            end

            @spec strip_privates({:ok, models :: [%__MODULE__{}]}) :: {:ok, [%__MODULE__{}]}
            def strip_privates({:ok, [%__MODULE__{} | _] = models}) when is_list(models) do
                {:ok, (models |> Enum.map(fn model -> Map.drop(model, @privates) end))}
            end

            @spec strip_privates(model :: %__MODULE__{}) :: {:ok, %__MODULE__{}}
            def strip_privates(%__MODULE__{} = model) do
                {:ok, stripped_model} = strip_privates({:ok, model})
                stripped_model
            end

            @spec strip_privates({:notfound, nil}) :: {:notfound, nil}
            def strip_privates({:notfound, nil}) do
                {:notfound, nil}
            end

            defp real_key(key) do
                case key do
                    :id -> :_id
                    other -> other
                end
            end

            defp real_value(value, key) do
                case key do
                    :id -> real_value_for_id(value)
                    other -> value
                end
            end

            defp real_value_for_id(%BSON.ObjectId{} = value) when is_map(value) do
                value
            end

            defp real_value_for_id(value) when is_binary(value) do
                BSON.ObjectId.decode!(value)
            end

            @spec collection_find(query :: Map.t, expect_many :: Boolean.t) :: {:ok, %__MODULE__{}} | {:ok, [%__MODULE__{}]} | {:notfound, nil}
            def collection_find(%{} = query, expect_many) when is_map(query) and is_boolean(expect_many) and expect_many == true do
                Mongo.find(:mongo, @collection, query, pool: DBConnection.Poolboy)
                |> Enum.to_list
                |> found_or_nil
            end

            @spec collection_find(query :: Map.t, expect_many :: Boolean.t) :: {:ok, %__MODULE__{}} | {:ok, [%__MODULE__{}]} | {:notfound, nil}
            def collection_find(%{} = query, expect_many) when is_map(query) and is_boolean(expect_many) and expect_many == false do
                Mongo.find_one(:mongo, @collection, query, pool: DBConnection.Poolboy)
                |> found_or_nil
            end

            @spec collection_find(model :: %__MODULE__{}, by_key :: Atom.t, expect_many :: Boolean.t) :: {:ok, %__MODULE__{}} | {:ok, [%__MODULE__{}]} | {:notfound, nil}
            def collection_find(%__MODULE__{} = model, by_key, expect_many \\ false) when is_map(model) and is_atom(by_key) and is_boolean(expect_many) do
                collection_find(%{real_key(by_key) => Map.get(model, by_key) |> real_value(by_key)}, expect_many)
            end

            @spec collection_insert(model :: %__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_insert(%__MODULE__{__struct__: _} = model) do
                model
                |> Map.from_struct()
                |> collection_insert()
            end

            @spec collection_insert(model :: %{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_insert(%{} = model) do
                Mongo.insert_one(:mongo, @collection, Map.delete(model, :id), pool: DBConnection.Poolboy)
                |> ok_or_error(:inserted_id, model)
            end

            @spec collection_insert_with_id(model :: %__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_insert_with_id(%__MODULE__{__struct__: _, id: id} = model) when is_map(id) do
                model
                |> Map.from_struct()
                |> collection_insert_with_id()
            end

            @spec collection_insert_with_id(model :: %{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_insert_with_id(%{} = model) do
                model
                |> Map.put(:_id, Map.get(model, :id))
                |> collection_insert()
            end

            @spec collection_update(model :: %__MODULE__{}, filter_key :: Atom.t) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_update(%__MODULE__{} = model, filter_key) do
                Mongo.find_one_and_update(:mongo, @collection, %{real_key(filter_key) => Map.get(model, filter_key) |> real_value(filter_key)}, %{"$set": (Map.from_struct(model) |> Enum.filter(fn {k, v} -> v != nil && k != filter_key end) |> Enum.into(%{}))}, pool: DBConnection.Poolboy, return_document: :after)
                |> found_or_nil
            end

            @spec collection_update(model :: %__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_update(%__MODULE__{} = model) do
                collection_update(model, :id)
            end

            @spec collection_update_manually(set :: %{}, query :: %{}) :: {:ok, %__MODULE__{}} | {:error, String.t}
            def collection_update_manually(%{} = set, %{} = query) do
                real_query = query
                             |> Map.keys()
                             |> Enum.map(fn (query_key) -> %{real_key(query_key) => Map.get(query, query_key) |> real_value(query_key)} end)
                             |> Enum.reduce(fn (query_map, previous_query_map) -> Map.merge(previous_query_map, query_map) end)

                Mongo.find_one_and_update(:mongo, @collection, real_query, set, pool: DBConnection.Poolboy, return_document: :after)
                |> found_or_nil
            end

        end
    end

    def keys_to_atoms(string_key_map) when is_map(string_key_map) do
        for {key, val} <- string_key_map, into: %{} do
            case Enumerable.impl_for val do
                nil -> {String.to_atom(key), val}
                _ -> {String.to_atom(key), keys_to_atoms(val)}
            end
        end
    end
    def keys_to_atoms(value), do: value
end

