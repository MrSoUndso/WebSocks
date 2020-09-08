defmodule Websocks.Pool do
  use GenServer

  # Client
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  # Server (callbacks)
  @impl true
  def init(state) do
    {:ok, state}
  end

end
