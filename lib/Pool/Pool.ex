defmodule Websocks.Pool do
  use GenServer

  # Client
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def add(pid, socket) do
    GenServer.cast(pid, {:add, socket})
  end

  def msg(pid, msg, from) do
    GenServer.cast(pid, {:msg, msg, from})
  end

  # Server (callbacks)
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, socket}, state) do
    Process.monitor(socket)
    {:noreply, [socket] ++ state}
  end

  @impl true
  def handle_cast({:msg, msg, from}, state) do
    Enum.each(state, fn pid -> unless pid == from do
      Websocks.Socket.send(pid, msg)
    end end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, object, _reason},state) do
    state = List.delete(state,object)
    {:noreply, state}
  end

end
