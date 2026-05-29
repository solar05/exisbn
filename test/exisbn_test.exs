defmodule ExisbnTest do
  use ExUnit.Case
  doctest Exisbn

  test "isbn10_checkdigit test" do
    assert Exisbn.isbn10_checkdigit("85-359-0277") == {:ok, "5"}
  end

  test "isbn13_checkdigit test" do
    assert {:ok, _} = Exisbn.hyphenate("9798893031355")
  end

  test "979-8 US hyphenation" do
    assert {:ok, "979-8-89303-135-5"} = Exisbn.hyphenate("9798893031355")
  end

  test "979-10 France hyphenation" do
    assert {:ok, "979-10-323-3653-3"} = Exisbn.hyphenate("9791032336533")
  end

  test "979-11 Korea hyphenation" do
    assert {:ok, "979-11-00-88888-9"} = Exisbn.hyphenate("9791100888889")
  end

  test "979-12 Italy hyphenation" do
    assert {:ok, "979-12-200-1234-8"} = Exisbn.hyphenate("9791220012348")
  end

  test "979-13 Spain hyphenation" do
    assert {:ok, "979-13-00-12345-2"} = Exisbn.hyphenate("9791300123452")
  end
end
