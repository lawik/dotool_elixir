defmodule DotoolTest do
  use ExUnit.Case
  doctest Dotool

  test "greets the world" do
    assert Dotool.hello() == :world
  end
end
