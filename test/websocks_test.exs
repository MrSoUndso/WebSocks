defmodule WebsocksTest do
  use ExUnit.Case
  doctest Websocks

  test "greets the world" do
    assert Websocks.hello() == :world
  end
end
