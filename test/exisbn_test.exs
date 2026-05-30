defmodule ExisbnTest do
  use ExUnit.Case
  doctest Exisbn

  test "isbn10_checkdigit test" do
    assert Exisbn.isbn10_checkdigit("85-359-0277") == {:ok, "5"}
  end

  test "isbn13_checkdigit test" do
    assert {:ok, _} = Exisbn.hyphenate("9798893031355")
  end

  test "publisher_zone returns unknown_group for unknown registration group" do
    assert {:error, :unknown_group} = Exisbn.publisher_zone("9799012345674")
  end

  test "publisher_zone returns invalid_isbn for structurally invalid input" do
    assert {:error, :invalid_isbn} = Exisbn.publisher_zone("str")
  end

  test "publisher_zone! raises Unknown registration group for unknown group" do
    assert_raise ArgumentError, "Unknown registration group", fn ->
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
    assert_raise ArgumentError, "No ISBN-10 equivalent", fn ->
      Exisbn.isbn13_to_10!("9798893031355")
    end
  end

  test "valid? accepts lowercase x as check digit" do
    assert Exisbn.valid?("887385107x")
  end

  test "fetch_checkdigit returns uppercase X for lowercase x input" do
    assert {:ok, "X"} = Exisbn.fetch_checkdigit("887385107x")
  end

  test "isbn10_to_13 accepts lowercase x check digit" do
    assert {:ok, _} = Exisbn.isbn10_to_13("887385107x")
  end

  test "fetch_body correctness via fetch_registrant_element and fetch_publication_element" do
    assert {:ok, "359"} = Exisbn.fetch_registrant_element("9788535902778")
    assert {:ok, "0277"} = Exisbn.fetch_publication_element("9788535902778")
    assert {:ok, "86197"} = Exisbn.fetch_registrant_element("978-1-86197-876-9")
    assert {:ok, "876"} = Exisbn.fetch_publication_element("978-1-86197-876-9")
  end

  test "fetch_registrant_element returns :unknown_publisher (not :invalid_isbn) when ranges non-empty but no match" do
    # 978-611 Thailand has empty ranges — tests the Enum.empty? guard
    assert {:error, :unknown_publisher} = Exisbn.fetch_registrant_element("9786110000000")

    # Both code paths (empty ranges and no-range-match) must return :unknown_publisher, not :invalid_isbn
    refute {:error, :invalid_isbn} == Exisbn.fetch_registrant_element("9786110000000")
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

  # fetch_metadata tests
  describe "fetch_metadata/1" do
    test "returns complete metadata for a known ISBN-13" do
      assert {:ok, meta} = Exisbn.fetch_metadata("9788535902778")
      assert meta.prefix == "978-85"
      assert meta.zone == "Brazil"
      assert meta.country_code == "BR"
      assert meta.registrant == "359"
      assert meta.publication == "0277"
      assert meta.checkdigit == "8"
    end

    test "returns metadata for ISBN-13 with hyphens" do
      assert {:ok, meta} = Exisbn.fetch_metadata("978-85-359-0277-8")
      assert meta.prefix == "978-85"
      assert meta.registrant == "359"
    end

    test "returns metadata for ISBN-10 (converted internally)" do
      assert {:ok, meta} = Exisbn.fetch_metadata("85-359-0277-5")
      assert meta.prefix == "978-85"
      assert meta.zone == "Brazil"
      assert meta.country_code == "BR"
      assert meta.registrant == "359"
      assert meta.publication == "0277"
      assert meta.checkdigit == "5"
    end

    test "returns nil country_code for multi-country groups" do
      assert {:ok, meta} = Exisbn.fetch_metadata("9780306406157")
      assert meta.country_code == nil
      assert meta.zone == "English language"
    end

    test "returns error for invalid ISBN" do
      assert {:error, :invalid_isbn} = Exisbn.fetch_metadata("invalid")
    end

    test "returns error for unknown registration group" do
      assert {:error, :unknown_group} = Exisbn.fetch_metadata("9799012345674")
    end

    test "returns error for ISBN with empty publisher ranges" do
      assert {:error, :unknown_publisher} = Exisbn.fetch_metadata("9786110000000")
    end
  end

  describe "fetch_metadata!/1" do
    test "returns metadata map on success" do
      assert %{prefix: "978-85", zone: "Brazil", country_code: "BR"} =
               Exisbn.fetch_metadata!("9788535902778")
    end

    test "raises ArgumentError for invalid ISBN" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.fetch_metadata!("invalid")
      end
    end

    test "raises ArgumentError for unknown group" do
      assert_raise ArgumentError, "Unknown registration group", fn ->
        Exisbn.fetch_metadata!("9799012345674")
      end
    end
  end

  # bang-function delegation tests
  describe "isbn10_checkdigit!/1" do
    test "returns digit on success" do
      assert Exisbn.isbn10_checkdigit!("85-359-0277") == "5"
    end

    test "returns X when check digit is 10" do
      assert Exisbn.isbn10_checkdigit!("887385107") == "X"
    end

    test "raises ArgumentError for invalid input" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.isbn10_checkdigit!("0str")
      end
    end
  end

  describe "isbn13_checkdigit!/1" do
    test "returns digit on success" do
      assert Exisbn.isbn13_checkdigit!("978-5-12345-678") == "1"
    end

    test "raises ArgumentError for invalid input" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.isbn13_checkdigit!("0str")
      end
    end
  end

  describe "isbn10_to_13!/1" do
    test "converts valid ISBN-10 to ISBN-13" do
      assert Exisbn.isbn10_to_13!("85-359-0277-5") == "9788535902778"
    end

    test "raises ArgumentError for invalid ISBN" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.isbn10_to_13!("invalid")
      end
    end
  end

  describe "publisher_country_code/1" do
    test "returns unknown_group for unknown registration group" do
      assert {:error, :unknown_group} = Exisbn.publisher_country_code("9799012345674")
    end

    test "returns invalid_isbn for structurally invalid input" do
      assert {:error, :invalid_isbn} = Exisbn.publisher_country_code("str")
    end
  end

  describe "publisher_country_code!/1" do
    test "returns country code string" do
      assert Exisbn.publisher_country_code!("9788535902778") == "BR"
    end

    test "returns nil for multi-country groups" do
      assert Exisbn.publisher_country_code!("9780306406157") == nil
    end

    test "raises ArgumentError for invalid ISBN" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.publisher_country_code!("str")
      end
    end

    test "raises Unknown registration group for unknown group" do
      assert_raise ArgumentError, "Unknown registration group", fn ->
        Exisbn.publisher_country_code!("9799012345674")
      end
    end
  end

  describe "fetch_checkdigit!/1" do
    test "returns the check digit" do
      assert Exisbn.fetch_checkdigit!("9788535902778") == "8"
    end

    test "returns X for ISBN-10 with X check digit" do
      assert Exisbn.fetch_checkdigit!("887385107X") == "X"
    end

    test "raises ArgumentError for invalid ISBN" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.fetch_checkdigit!("str")
      end
    end
  end

  describe "hyphenate!/1" do
    test "hyphenates ISBN-13" do
      assert Exisbn.hyphenate!("9788535902778") == "978-85-359-0277-8"
    end

    test "hyphenates ISBN-10" do
      assert Exisbn.hyphenate!("0306406152") == "0-306-40615-2"
    end

    test "raises ArgumentError for invalid ISBN" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.hyphenate!("str")
      end
    end
  end

  describe "bang functions propagate specific error reasons" do
    test "fetch_prefix! raises Unknown registration group for unregistered 979 group" do
      assert_raise ArgumentError, "Unknown registration group", fn ->
        Exisbn.fetch_prefix!("9799012345674")
      end
    end

    test "fetch_registrant_element! raises Unknown registration group" do
      assert_raise ArgumentError, "Unknown registration group", fn ->
        Exisbn.fetch_registrant_element!("9799012345674")
      end
    end

    test "fetch_registrant_element! raises Unknown publisher for empty ranges" do
      assert_raise ArgumentError, "Unknown publisher", fn ->
        Exisbn.fetch_registrant_element!("9786110000000")
      end
    end

    test "fetch_publication_element! raises Unknown registration group" do
      assert_raise ArgumentError, "Unknown registration group", fn ->
        Exisbn.fetch_publication_element!("9799012345674")
      end
    end

    test "fetch_publication_element! raises Unknown publisher for empty ranges" do
      assert_raise ArgumentError, "Unknown publisher", fn ->
        Exisbn.fetch_publication_element!("9786110000000")
      end
    end

    test "fetch_metadata! raises Unknown publisher for empty ranges" do
      assert_raise ArgumentError, "Unknown publisher", fn ->
        Exisbn.fetch_metadata!("9786110000000")
      end
    end
  end

  # normalize/1 tests
  describe "valid? validates by normalized length" do
    test "accepts ISBNs with unconventional separator grouping" do
      # Dots with non-standard grouping: digits normalize to valid ISBN-13
      assert Exisbn.valid?("978.853590277.8")
    end

    test "rejects string that normalizes to empty" do
      refute Exisbn.valid?("invalid")
    end

    test "rejects string that normalizes to wrong length" do
      refute Exisbn.valid?("97885359027")
    end
  end

  describe "isbn_type/1" do
    test "returns :isbn13 for a valid ISBN-13" do
      assert Exisbn.isbn_type("9788535902778") == :isbn13
    end

    test "returns :isbn13 for a hyphenated ISBN-13" do
      assert Exisbn.isbn_type("978-85-359-0277-8") == :isbn13
    end

    test "returns :isbn10 for a valid ISBN-10" do
      assert Exisbn.isbn_type("85-359-0277-5") == :isbn10
    end

    test "returns :isbn10 for a valid ISBN-10 with X check digit" do
      assert Exisbn.isbn_type("887385107X") == :isbn10
    end

    test "returns :invalid for a structurally invalid string" do
      assert Exisbn.isbn_type("invalid") == :invalid
    end

    test "returns :invalid for wrong-length digit string" do
      assert Exisbn.isbn_type("12345") == :invalid
    end

    test "returns :invalid when check digit is wrong" do
      assert Exisbn.isbn_type("9788535902770") == :invalid
    end
  end

  describe "isbn13_prefix_group/1" do
    test "returns 978 for standard ISBN-13" do
      assert {:ok, "978"} = Exisbn.isbn13_prefix_group("9788535902778")
    end

    test "returns 979 for 979-prefix ISBN-13" do
      assert {:ok, "979"} = Exisbn.isbn13_prefix_group("9798893031355")
    end

    test "accepts hyphenated ISBN-13" do
      assert {:ok, "978"} = Exisbn.isbn13_prefix_group("978-85-359-0277-8")
    end

    test "returns error for valid ISBN-10" do
      assert {:error, :invalid_isbn} = Exisbn.isbn13_prefix_group("85-359-0277-5")
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_isbn} = Exisbn.isbn13_prefix_group("str")
    end
  end

  describe "isbn13_prefix_group!/1" do
    test "returns prefix group on success" do
      assert Exisbn.isbn13_prefix_group!("9788535902778") == "978"
      assert Exisbn.isbn13_prefix_group!("9798893031355") == "979"
    end

    test "raises ArgumentError for invalid input" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.isbn13_prefix_group!("str")
      end
    end

    test "raises ArgumentError for ISBN-10" do
      assert_raise ArgumentError, "Invalid ISBN", fn ->
        Exisbn.isbn13_prefix_group!("85-359-0277-5")
      end
    end
  end

  describe "normalize/1" do
    test "strips hyphens from ISBN-13" do
      assert Exisbn.normalize("978-85-359-0277-8") == "9788535902778"
    end

    test "strips spaces from ISBN-13" do
      assert Exisbn.normalize("978 85 359 0277 8") == "9788535902778"
    end

    test "strips hyphens from ISBN-10" do
      assert Exisbn.normalize("85-359-0277-5") == "8535902775"
    end

    test "upcases lowercase x check digit" do
      assert Exisbn.normalize("887385107x") == "887385107X"
    end

    test "is idempotent on already-clean ISBN" do
      assert Exisbn.normalize("9788535902778") == "9788535902778"
    end

    test "drops non-digit non-X characters" do
      assert Exisbn.normalize("978.85.359.0277.8") == "9788535902778"
    end

    test "returns empty string for fully non-numeric input" do
      assert Exisbn.normalize("invalid") == ""
    end
  end
end
