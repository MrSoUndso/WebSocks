defmodule Websocks.PoolHandler do
  use GenServer

  # Client
  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def add(name) do
    GenServer.cast(Websocks.PoolHandler,{:new, name})
    :ok
  end

  def get_pools() do
    GenServer.call(Websocks.PoolHandler,:get_all)
  end

  def remove(name) do
    GenServer.cast(Websocks.PoolHandler, {:remove, name})
    :ok
  end

  def get(name) do
    GenServer.call(Websocks.PoolHandler, {:get,name})
  end

  # Server (callbacks)

  @impl true
  def init(arg) do
    {:ok, arg}
  end

  @impl true
  def handle_cast({:new,name},state) do
    {:ok, pid} = DynamicSupervisor.start_child(Websocks.PoolSupervisor,{Websocks.Pool,restart: :transient})
    state = Map.put(state,name,pid)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove, name}, state) do
    DynamicSupervisor.terminate_child(Websocks.PoolSupervisor,Map.get(state, name))
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
