defmodule VividPuppetTest do
  use ExUnit.Case
  doctest VividPuppet

  test "greets the world" do
    assert VividPuppet.hello() == :world
  end
end
