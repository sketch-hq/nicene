defmodule NiceneTest do
  use ExUnit.Case
  doctest Nicene

  test "greets the world" do
    assert Nicene.hello() == :world
  end
end
