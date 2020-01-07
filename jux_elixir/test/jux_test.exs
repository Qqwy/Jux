defmodule JuxTest do
  use ExUnit.Case
  doctest Jux

  test "greets the world" do
    assert Jux.hello() == :world
  end
end
