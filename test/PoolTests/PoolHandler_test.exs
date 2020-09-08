defmodule PoolHandlerTest do
  use ExUnit.Case, async: true
  alias Websocks.PoolHandler
  doctest PoolHandler

  setup do
    start_supervised!(PoolHandler)
    %{}
  end

  test "adding two pools and checking if they are there" do
    assert PoolHandler.add(:first, nil) == :ok
    assert PoolHandler.add(:second, nil) == :ok
    assert PoolHandler.get_pools() == {:ok,%{:first => nil, :second => nil}}
  end

  test "adding one pool" do
    assert PoolHandler.get(:name) == {:error,:not_found}
    assert PoolHandler.add(:name, nil) == :ok
    assert PoolHandler.get(:name) == {:ok, nil}
  end

  test "removing a pool" do
    PoolHandler.add(:name, nil)
    assert PoolHandler.remove(:name) == :ok
    assert PoolHandler.get(:name) == {:error,:not_found}
  end
end