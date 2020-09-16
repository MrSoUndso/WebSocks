defmodule PoolHandlerTest do
  use ExUnit.Case, async: true
  alias Websocks.PoolHandler
  doctest PoolHandler

  setup do
    %{}
  end

  test "adding two pools and checking if they are there" do
    assert PoolHandler.add(:first) == :ok
    assert PoolHandler.add(:second) == :ok
    {:ok,%{:first => pid1, :second => pid2}} = PoolHandler.get_pools()
    assert is_pid(pid1)
    assert is_pid(pid2)
  end

  test "adding one pool" do
    assert PoolHandler.get(:add_test) == {:error,:not_found}
    assert PoolHandler.add(:add_test) == :ok
    {:ok, pid} = PoolHandler.get(:add_test)
    assert is_pid(pid)
  end

  test "removing a pool" do
    PoolHandler.add(:remove_test)
    assert PoolHandler.remove(:remove_test) == :ok
    assert PoolHandler.get(:remove_test) == {:error,:not_found}
  end
end
