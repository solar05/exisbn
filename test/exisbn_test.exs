defmodule ExisbnTest do
  use ExUnit.Case
  doctest Exisbn

  test "isbn10_checkdigit test" do
    assert Exisbn.isbn10_checkdigit("85-359-0277") == {:ok, "5"}
  end
end
