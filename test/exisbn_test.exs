defmodule ExisbnTest do
  use ExUnit.Case
  doctest Exisbn

  test "isbn10? test" do
    assert Exisbn.isbn10?("0545010225") == true
  end
end
