defmodule Paperwork.Helpers.Map do
    require Logger

    def unstruct!(map) when is_map(map) do
        Enum.reduce(
            map,
            %{},
            fn({map_key, map_val}, acc) ->
                cond do
                    is_map(map_val) and Map.has_key?(map_val, :__struct__) ->
                        new_map_val =
                            map_val
                            |> Map.from_struct()
                            |> unstruct!()
                        Map.put(acc, map_key, new_map_val)

                    true ->
                        Map.put(acc, map_key, map_val)

                end
            end
        )
    end

end
