defmodule ChatMeTest do
  use ExUnit.Case
  doctest ChatMe

  test "greets the world" do
    assert ChatMe.hello() == :world
  end
end
