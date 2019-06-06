defmodule DdMonitorCliTest do
  use ExUnit.Case
  doctest DdMonitorCli

  test "greets the world" do
    assert DdMonitorCli.hello() == :world
  end
end
