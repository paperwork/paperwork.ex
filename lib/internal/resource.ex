defmodule Paperwork.Internal.Resource do
    def configs(),     do: Confex.fetch_env!(:paperwork, :internal)[:configs]
    def users(),       do: Confex.fetch_env!(:paperwork, :internal)[:users]
    def notes(),       do: Confex.fetch_env!(:paperwork, :internal)[:notes]
    def attachments(), do: Confex.fetch_env!(:paperwork, :internal)[:attachments]
    def journals(),    do: Confex.fetch_env!(:paperwork, :internal)[:journals]
end
