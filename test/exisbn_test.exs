defmodule ExisbnTest do
  use ExUnit.Case
  doctest Exisbn

  test "isbn10_checkdigit test" do
    assert Exisbn.isbn10_checkdigit("85-359-0277") == {:ok, "5"}
  end

  test "isbn13_checkdigit test" do
    assert {:ok, _} = Exisbn.hyphenate("9798893031355")
  end

  test "publisher_zone returns error for unknown registration group" do
    assert {:error, :invalid_isbn} = Exisbn.publisher_zone("9799012345674")
  end

  test "publisher_zone! raises for unknown registration group" do
    assert_raise ArgumentError, "Invalid ISBN", fn ->
      Exisbn.publisher_zone!("9799012345674")
    end
  end

  test "hyphenate returns error for ISBN with empty publisher ranges" do
    # 978-611 Thailand has ranges: []
    assert {:error, :invalid_isbn} = Exisbn.hyphenate("9786110000000")
  end

  test "fetch_registrant_element returns unknown_publisher for empty ranges" do
    assert {:error, :unknown_publisher} = Exisbn.fetch_registrant_element("9786110000000")
  end

  test "fetch_publication_element returns unknown_publisher for empty ranges" do
    assert {:error, :unknown_publisher} = Exisbn.fetch_publication_element("9786110000000")
  end

  test "fetch_prefix returns unknown_group for unregistered group" do
    assert {:error, :unknown_group} = Exisbn.fetch_prefix("9799012345674")
  end

  test "fetch_registrant_element returns unknown_group for unregistered group" do
    assert {:error, :unknown_group} = Exisbn.fetch_registrant_element("9799012345674")
  end

  test "isbn13_to_10 returns no_isbn10_equivalent for 979-prefix ISBN" do
    assert {:error, :no_isbn10_equivalent} = Exisbn.isbn13_to_10("9798893031355")
  end

  test "isbn13_to_10! raises for 979-prefix ISBN" do
    assert_raise ArgumentError, "Invalid ISBN", fn ->
      Exisbn.isbn13_to_10!("9798893031355")
    end
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
