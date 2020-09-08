defmodule Websocks.PoolHandler do
  use GenServer

  # Client
  def start_link([]) do
    GenServer.start_link(__MODULE__, %{}, name: PoolHandler)
  end

  def add(name,pid) do
    GenServer.cast(PoolHandler,{:new, name, pid})
    :ok
  end

  def get_pools() do
    GenServer.call(PoolHandler,:get_all)
  end

  def remove(name) do
    GenServer.cast(PoolHandler, {:remove, name})
    :ok
  end

  def get(name) do
    GenServer.call(PoolHandler, {:get,name})
  end

  # Server (callbacks)

  @impl true
  def init(arg) when is_map(arg) do
    {:ok, arg}
  end

  @impl true
  def handle_cast({:new,name, pid},state) do
    state = Map.put(state,name,pid)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove, name}, state) do
    state = Map.delete(state,name)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply,{:ok,state},state}
  end

  @impl true
  def handle_call({:get, name}, _from, state) do
    value = Map.get(state, name, :error)
    case value do
      :error -> {:reply, {:error,:not_found}, state}
      _ -> {:reply, {:ok, value}, state}
    end
  end

end
