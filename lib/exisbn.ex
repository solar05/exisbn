defmodule Exisbn do
  alias Exisbn.Regions

  @non_isbn_chars ~r/[^0-9X]/

  @moduledoc """
  Documentation for `Exisbn`.
  """

  @doc """
  Takes an ISBN 10 code as string, returns its check digit.

  ## Examples

      iex> Exisbn.isbn10_checkdigit("85-359-0277")
      {:ok, "5"}
      iex> Exisbn.isbn10_checkdigit("5-02-013850")
      {:ok, "9"}
      iex> Exisbn.isbn10_checkdigit("0str")
      {:error, :invalid_isbn}
      iex> Exisbn.isbn10_checkdigit("887385107")
      {:ok, "X"}
  """
  @spec isbn10_checkdigit(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def isbn10_checkdigit(isbn) when is_bitstring(isbn) do
    if String.length(normalize(isbn)) in 8..10 do
      case calculate_isbn10_checkdigit(isbn) do
        {:ok, digit} -> {:ok, digit}
        {:error, _} -> {:error, :invalid_isbn}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `isbn10_checkdigit/1`, but raises exception.

  ## Examples

      iex> Exisbn.isbn10_checkdigit!("85-359-0277")
      "5"
      iex> Exisbn.isbn10_checkdigit!("5-02-013850")
      "9"
      iex> Exisbn.isbn10_checkdigit!("0str")
      ** (ArgumentError) Invalid ISBN
      iex> Exisbn.isbn10_checkdigit!("887385107")
      "X"
  """
  @spec isbn10_checkdigit!(String.t()) :: String.t()
  def isbn10_checkdigit!(isbn) when is_bitstring(isbn) do
    case isbn10_checkdigit(isbn) do
      {:ok, digit} -> digit
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN 13 code as string, returns its check digit.

  ## Examples

      iex> Exisbn.isbn13_checkdigit("978-5-12345-678")
      {:ok, "1"}
      iex> Exisbn.isbn13_checkdigit("978-0-306-40615")
      {:ok, "7"}
      iex> Exisbn.isbn13_checkdigit("0str")
      {:error, :invalid_isbn}
  """
  @spec isbn13_checkdigit(binary) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def isbn13_checkdigit(isbn) when is_bitstring(isbn) do
    if String.length(normalize(isbn)) in 11..13 do
      case calculate_isbn13_checkdigit(isbn) do
        {:ok, digit} -> {:ok, digit}
        {:error, _} -> {:error, :invalid_isbn}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `isbn13_checkdigit/1`, but raises exception.

  ## Examples

      iex> Exisbn.isbn13_checkdigit!("978-5-12345-678")
      "1"
      iex> Exisbn.isbn13_checkdigit!("978-0-306-40615")
      "7"
      iex> Exisbn.isbn13_checkdigit!("0str")
      ** (ArgumentError) Invalid ISBN
  """
  @spec isbn13_checkdigit!(binary) :: String.t()
  def isbn13_checkdigit!(isbn) when is_bitstring(isbn) do
    case isbn13_checkdigit(isbn) do
      {:ok, digit} -> digit
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN (10 or 13) and checks its validity by its check digit

  ## Examples

      iex> Exisbn.checkdigit_correct?("85-359-0277-5")
      true
      iex> Exisbn.checkdigit_correct?("978-5-12345-678-1")
      true
      iex> Exisbn.checkdigit_correct?("978-5-12345-678")
      false
  """
  @spec checkdigit_correct?(String.t()) :: boolean
  def checkdigit_correct?(isbn) when is_bitstring(isbn) do
    normalized = normalize(isbn)

    result =
      if String.length(normalized) == 10 do
        isbn10_checkdigit(normalized)
      else
        isbn13_checkdigit(normalized)
      end

    case result do
      {:ok, digit} -> digit == String.last(normalized)
      {:error, _} -> false
    end
  end

  def checkdigit_correct?(_), do: false

  @doc """
  Takes an ISBN (10 or 13) and checks its validity by checking the checkdigit, length and characters.

  ## Examples

      iex> Exisbn.valid?("978-5-12345-678-1")
      true
      iex> Exisbn.valid?("978-5-12345-678")
      false
      iex> Exisbn.valid?("85-359-0277-5")
      true
      iex> Exisbn.valid?("85-359-0277")
      false
  """
  @spec valid?(String.t()) :: boolean
  def valid?(isbn) when is_bitstring(isbn) do
    normalized = normalize(isbn)
    correct_normalized_length?(normalized) and checkdigit_correct_for_normalized?(normalized)
  end

  def valid?(_), do: false

  @doc """
  Takes an ISBN 10 and converts it to ISBN 13.

  ## Examples

      iex> Exisbn.isbn10_to_13("85-359-0277-5")
      {:ok, "9788535902778"}
      iex> Exisbn.valid?("9788535902778")
      true
      iex> Exisbn.isbn10_to_13("0306406152")
      {:ok, "9780306406157"}
      iex> Exisbn.valid?("9780306406157")
      true
      iex> Exisbn.isbn10_to_13("0-19-853453123")
      {:error, :invalid_isbn}
  """
  @spec isbn10_to_13(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def isbn10_to_13(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      first_chars = "978#{String.slice(normalize(isbn), 0..8)}"
      {:ok, checkdigit} = isbn13_checkdigit(first_chars)
      {:ok, "#{first_chars}#{checkdigit}"}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `isbn10_to_13/1`, but raises exception.

  ## Examples

      iex> Exisbn.isbn10_to_13!("85-359-0277-5")
      "9788535902778"
      iex> Exisbn.valid?("9788535902778")
      true
      iex> Exisbn.isbn10_to_13!("0306406152")
      "9780306406157"
      iex> Exisbn.valid?("9780306406157")
      true
      iex> Exisbn.isbn10_to_13!("0-19-853453123")
      ** (ArgumentError) Invalid ISBN
  """
  @spec isbn10_to_13!(String.t()) :: String.t()
  def isbn10_to_13!(isbn) when is_bitstring(isbn) do
    case isbn10_to_13(isbn) do
      {:ok, result} -> result
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN 13 and converts it to ISBN 10.

  ISBNs with prefix `979` have no ISBN-10 equivalent and return
  `{:error, :no_isbn10_equivalent}`.

  ## Examples

      iex> Exisbn.isbn13_to_10("9788535902778")
      {:ok, "8535902775"}
      iex> Exisbn.valid?("8535902775")
      true
      iex> Exisbn.isbn13_to_10("9780306406157")
      {:ok, "0306406152"}
      iex> Exisbn.valid?("0306406152")
      true
      iex> Exisbn.isbn13_to_10("str")
      {:error, :invalid_isbn}
      iex> Exisbn.isbn13_to_10("9798893031355")
      {:error, :no_isbn10_equivalent}
  """
  @spec isbn13_to_10(String.t()) ::
          {:ok, String.t()} | {:error, :invalid_isbn | :no_isbn10_equivalent}
  def isbn13_to_10(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      normalized = normalize(isbn)

      if String.starts_with?(normalized, "979") do
        {:error, :no_isbn10_equivalent}
      else
        first_chars = normalized |> drop_chars(3) |> String.slice(0..8)
        {:ok, checkdigit} = isbn10_checkdigit(first_chars)
        {:ok, "#{first_chars}#{checkdigit}"}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `isbn13_to_10/1`, but raises exception.

  ## Examples

      iex> Exisbn.isbn13_to_10!("9788535902778")
      "8535902775"
      iex> Exisbn.valid?("8535902775")
      true
      iex> Exisbn.isbn13_to_10!("9780306406157")
      "0306406152"
      iex> Exisbn.valid?("0306406152")
      true
      iex> Exisbn.isbn13_to_10!("str")
      ** (ArgumentError) Invalid ISBN

      iex> Exisbn.isbn13_to_10!("9798893031355")
      ** (ArgumentError) No ISBN-10 equivalent
  """
  @spec isbn13_to_10!(String.t()) :: String.t()
  def isbn13_to_10!(isbn) when is_bitstring(isbn) do
    case isbn13_to_10(isbn) do
      {:ok, result} -> result
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its publisher zone.

  Returns `{:error, :invalid_isbn}` for structurally invalid ISBNs and
  `{:error, :unknown_group}` when the registration group is not in the dataset.

  ## Examples

      iex> Exisbn.publisher_zone("9788535902778")
      {:ok, "Brazil"}
      iex> Exisbn.publisher_zone("2-1234-5680-2")
      {:ok, "French language"}
      iex> Exisbn.publisher_zone("str")
      {:error, :invalid_isbn}
      iex> Exisbn.publisher_zone("9799012345674")
      {:error, :unknown_group}
  """
  @spec publisher_zone(String.t()) ::
          {:ok, String.t()} | {:error, :invalid_isbn | :unknown_group}
  def publisher_zone(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn = prepare_isbn_13(isbn)

      case fetch_info(prepared_isbn) do
        nil -> {:error, :unknown_group}
        info -> {:ok, Map.get(info, "name")}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `publisher_zone/1`, but raises exception.

  ## Examples

      iex> Exisbn.publisher_zone!("9788535902778")
      "Brazil"
      iex> Exisbn.publisher_zone!("2-1234-5680-2")
      "French language"
      iex> Exisbn.publisher_zone!("str")
      ** (ArgumentError) Invalid ISBN

      iex> Exisbn.publisher_zone!("9799012345674")
      ** (ArgumentError) Unknown registration group
  """
  @spec publisher_zone!(String.t()) :: String.t()
  def publisher_zone!(isbn) when is_bitstring(isbn) do
    case publisher_zone(isbn) do
      {:ok, zone} -> zone
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its ISO 3166-1 alpha-2 country code.

  Returns `{:ok, nil}` for groups that span multiple countries or
  language areas (e.g. English language, French language, German language,
  former U.S.S.R, Caribbean Community).

  ## Examples

      iex> Exisbn.publisher_country_code("9788535902778")
      {:ok, "BR"}
      iex> Exisbn.publisher_country_code("9780306406157")
      {:ok, nil}
      iex> Exisbn.publisher_country_code("str")
      {:error, :invalid_isbn}
  """
  @spec publisher_country_code(String.t()) ::
          {:ok, String.t() | nil} | {:error, :invalid_isbn | :unknown_group}
  def publisher_country_code(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn = prepare_isbn_13(isbn)

      case fetch_info(prepared_isbn) do
        nil -> {:error, :unknown_group}
        info -> {:ok, Map.get(info, "country_code")}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `publisher_country_code/1`, but raises exception.

  ## Examples

      iex> Exisbn.publisher_country_code!("9788535902778")
      "BR"
      iex> Exisbn.publisher_country_code!("9780306406157")
      nil
      iex> Exisbn.publisher_country_code!("str")
      ** (ArgumentError) Invalid ISBN
  """
  @spec publisher_country_code!(String.t()) :: String.t() | nil
  def publisher_country_code!(isbn) when is_bitstring(isbn) do
    case publisher_country_code(isbn) do
      {:ok, code} -> code
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its prefix.

  Returns `{:error, :unknown_group}` when the ISBN is structurally valid but belongs
  to a registration group not present in the dataset.

  ## Examples

      iex> Exisbn.fetch_prefix("9788535902778")
      {:ok, "978-85"}
      iex> Exisbn.fetch_prefix("2-1234-5680-2")
      {:ok, "978-2"}
      iex> Exisbn.fetch_prefix("str")
      {:error, :invalid_isbn}
      iex> Exisbn.fetch_prefix("9799012345674")
      {:error, :unknown_group}
  """
  @spec fetch_prefix(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn | :unknown_group}
  def fetch_prefix(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn = prepare_isbn_13(isbn)

      case search_prefix_range(String.slice(prepared_isbn, 0..2), drop_chars(prepared_isbn, 3)) do
        nil -> {:error, :unknown_group}
        prefix -> {:ok, prefix}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `fetch_prefix/1`, but raises exception.

  ## Examples

      iex> Exisbn.fetch_prefix!("9788535902778")
      "978-85"
      iex> Exisbn.fetch_prefix!("2-1234-5680-2")
      "978-2"
      iex> Exisbn.fetch_prefix!("str")
      ** (ArgumentError) Invalid ISBN

      iex> Exisbn.fetch_prefix!("9799012345674")
      ** (ArgumentError) Unknown registration group
  """
  @spec fetch_prefix!(String.t()) :: String.t()
  def fetch_prefix!(isbn) when is_bitstring(isbn) do
    case fetch_prefix(isbn) do
      {:ok, prefix} -> prefix
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its checkdigit.

  ## Examples

      iex> Exisbn.fetch_checkdigit("9788535902778")
      {:ok, "8"}
      iex> Exisbn.fetch_checkdigit("2-1234-5680-2")
      {:ok, "2"}
      iex> Exisbn.fetch_checkdigit("str")
      {:error, :invalid_isbn}
      iex> Exisbn.fetch_checkdigit("887385107X")
      {:ok, "X"}
  """
  @spec fetch_checkdigit(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def fetch_checkdigit(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      {:ok, isbn |> normalize() |> String.last()}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `fetch_checkdigit/1`, but raises exception.

  ## Examples

      iex> Exisbn.fetch_checkdigit!("9788535902778")
      "8"
      iex> Exisbn.fetch_checkdigit!("2-1234-5680-2")
      "2"
      iex> Exisbn.fetch_checkdigit!("str")
      ** (ArgumentError) Invalid ISBN
      iex> Exisbn.fetch_checkdigit!("887385107X")
      "X"
  """
  @spec fetch_checkdigit!(String.t()) :: String.t()
  def fetch_checkdigit!(isbn) when is_bitstring(isbn) do
    case fetch_checkdigit(isbn) do
      {:ok, digit} -> digit
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its registrant element.

  Returns `{:error, :unknown_group}` when the registration group is not in the dataset,
  and `{:error, :unknown_publisher}` when the group has no publisher ranges defined.

  ## Examples

      iex> Exisbn.fetch_registrant_element("9788535902778")
      {:ok, "359"}
      iex> Exisbn.fetch_registrant_element("978-1-86197-876-9")
      {:ok, "86197"}
      iex> Exisbn.fetch_registrant_element("9789529351787")
      {:ok, "93"}
      iex> Exisbn.fetch_registrant_element("str")
      {:error, :invalid_isbn}
      iex> Exisbn.fetch_registrant_element("9799012345674")
      {:error, :unknown_group}
      iex> Exisbn.fetch_registrant_element("9786110000000")
      {:error, :unknown_publisher}
  """
  @spec fetch_registrant_element(String.t()) ::
          {:ok, String.t()}
          | {:error, :invalid_isbn | :unknown_group | :unknown_publisher}
  def fetch_registrant_element(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn = prepare_isbn_13(isbn)

      with {:ok, prefix} <- fetch_prefix(prepared_isbn) do
        registrant_with_prefix(prepared_isbn, prefix)
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `fetch_registrant_element/1`, but raises exception.

  ## Examples

      iex> Exisbn.fetch_registrant_element!("9788535902778")
      "359"
      iex> Exisbn.fetch_registrant_element!("978-1-86197-876-9")
      "86197"
      iex> Exisbn.fetch_registrant_element!("9789529351787")
      "93"
      iex> Exisbn.fetch_registrant_element!("str")
      ** (ArgumentError) Invalid ISBN

      iex> Exisbn.fetch_registrant_element!("9799012345674")
      ** (ArgumentError) Unknown registration group

      iex> Exisbn.fetch_registrant_element!("9786110000000")
      ** (ArgumentError) Unknown publisher
  """
  @spec fetch_registrant_element!(String.t()) :: String.t()
  def fetch_registrant_element!(isbn) when is_bitstring(isbn) do
    case fetch_registrant_element(isbn) do
      {:ok, result} -> result
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN and returns its publication element.

  Propagates `{:error, :unknown_group}` and `{:error, :unknown_publisher}`
  from `fetch_registrant_element/1`.

  ## Examples

      iex> Exisbn.fetch_publication_element("978-1-86197-876-9")
      {:ok, "876"}
      iex> Exisbn.fetch_publication_element("9789529351787")
      {:ok, "5178"}
      iex> Exisbn.fetch_publication_element("str")
      {:error, :invalid_isbn}
      iex> Exisbn.fetch_publication_element("9799012345674")
      {:error, :unknown_group}
      iex> Exisbn.fetch_publication_element("9786110000000")
      {:error, :unknown_publisher}
  """
  @spec fetch_publication_element(String.t()) ::
          {:ok, String.t()}
          | {:error, :invalid_isbn | :unknown_group | :unknown_publisher}
  def fetch_publication_element(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn = prepare_isbn_13(isbn)

      with {:ok, prefix} <- fetch_prefix(prepared_isbn),
           {:ok, registrant} <- registrant_with_prefix(prepared_isbn, prefix) do
        publication_with_prefix_and_registrant(prepared_isbn, prefix, registrant)
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `fetch_publication_element/1`, but raises exception.

  ## Examples

      iex> Exisbn.fetch_publication_element!("978-1-86197-876-9")
      "876"
      iex> Exisbn.fetch_publication_element!("9789529351787")
      "5178"
      iex> Exisbn.fetch_publication_element!("str")
      ** (ArgumentError) Invalid ISBN

      iex> Exisbn.fetch_publication_element!("9799012345674")
      ** (ArgumentError) Unknown registration group

      iex> Exisbn.fetch_publication_element!("9786110000000")
      ** (ArgumentError) Unknown publisher
  """
  @spec fetch_publication_element!(String.t()) :: String.t()
  def fetch_publication_element!(isbn) when is_bitstring(isbn) do
    case fetch_publication_element(isbn) do
      {:ok, result} -> result
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Takes an ISBN (10 or 13) and hyphenates it.

  ## Examples

      iex> Exisbn.hyphenate("9788535902778")
      {:ok, "978-85-359-0277-8"}
      iex> Exisbn.hyphenate("0306406152")
      {:ok, "0-306-40615-2"}
      iex> Exisbn.hyphenate("str")
      {:error, :invalid_isbn}
  """
  @spec hyphenate(String.t()) ::
          {:ok, String.t()} | {:error, :invalid_isbn | :unknown_group | :unknown_publisher}
  def hyphenate(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      if isbn10?(isbn), do: hyphenate_isbn10(isbn), else: hyphenate_isbn13(isbn)
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `hyphenate/1`, but raises exception.

  ## Examples

      iex> Exisbn.hyphenate!("9788535902778")
      "978-85-359-0277-8"
      iex> Exisbn.hyphenate!("0306406152")
      "0-306-40615-2"
      iex> Exisbn.hyphenate!("str")
      ** (ArgumentError) Invalid ISBN
  """
  @spec hyphenate!(String.t()) :: String.t()
  def hyphenate!(isbn) when is_bitstring(isbn) do
    case hyphenate(isbn) do
      {:ok, result} -> result
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Checks if an ISBN (10 or 13) code is correctly hyphenated. If ISBN incorrect, that count as no.

  ## Examples

      iex> Exisbn.correct_hyphens?("978-85-359-0277-8")
      true
      iex> Exisbn.correct_hyphens?("97-8853590277-8")
      false
      iex> Exisbn.correct_hyphens?("0-306-40615-2")
      true
      iex> Exisbn.correct_hyphens?("03-064-06152")
      false
      iex> Exisbn.correct_hyphens?("str")
      false
  """
  @spec correct_hyphens?(binary) :: boolean
  def correct_hyphens?(isbn) when is_bitstring(isbn) do
    case hyphenate(isbn) do
      {:ok, hyphenated} -> isbn == hyphenated
      {:error, _} -> false
    end
  end

  @doc """
  Returns all ISBN metadata in a single call.

  Fetches the prefix, publisher zone, ISO country code, registrant element,
  publication element, and check digit without redundant lookups.

  Returns `{:error, :invalid_isbn}` for structurally invalid ISBNs,
  `{:error, :unknown_group}` when the registration group is not in the dataset,
  and `{:error, :unknown_publisher}` when the group has no publisher ranges defined.

  ## Examples

      iex> Exisbn.fetch_metadata("9788535902778")
      {:ok, %{checkdigit: "8", country_code: "BR", prefix: "978-85", publication: "0277", registrant: "359", zone: "Brazil"}}

      iex> Exisbn.fetch_metadata("9780306406157")
      {:ok, %{checkdigit: "7", country_code: nil, prefix: "978-0", publication: "40615", registrant: "306", zone: "English language"}}

      iex> Exisbn.fetch_metadata("str")
      {:error, :invalid_isbn}

      iex> Exisbn.fetch_metadata("9799012345674")
      {:error, :unknown_group}

  """
  @spec fetch_metadata(String.t()) ::
          {:ok,
           %{
             prefix: String.t(),
             zone: String.t(),
             country_code: String.t() | nil,
             registrant: String.t(),
             publication: String.t(),
             checkdigit: String.t()
           }}
          | {:error, :invalid_isbn | :unknown_group | :unknown_publisher}
  def fetch_metadata(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      isbn13 = prepare_isbn_13(isbn)

      with {:ok, prefix} <- fetch_prefix(isbn13),
           {:ok, registrant} <- registrant_with_prefix(isbn13, prefix),
           {:ok, publication} <-
             publication_with_prefix_and_registrant(isbn13, prefix, registrant) do
        info = Map.get(Regions.dataset(), prefix)

        {:ok,
         %{
           prefix: prefix,
           zone: Map.get(info, "name"),
           country_code: Map.get(info, "country_code"),
           registrant: registrant,
           publication: publication,
           checkdigit: isbn |> normalize() |> String.last()
         }}
      end
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `fetch_metadata/1`, but raises exception.

  ## Examples

      iex> meta = Exisbn.fetch_metadata!("9788535902778")
      iex> meta.zone
      "Brazil"
      iex> meta.country_code
      "BR"

      iex> Exisbn.fetch_metadata!("str")
      ** (ArgumentError) Invalid ISBN

  """
  @spec fetch_metadata!(String.t()) :: map()
  def fetch_metadata!(isbn) when is_bitstring(isbn) do
    case fetch_metadata(isbn) do
      {:ok, metadata} -> metadata
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  defp calculate_isbn10_checkdigit(isbn) do
    normalized = normalize(isbn)

    if String.length(normalized) in 8..10 do
      nsum = isbn10_sum(binary_part(normalized, 0, min(9, byte_size(normalized))), 10, 0)
      digit = Integer.mod(11 - Integer.mod(nsum, 11), 11)
      {:ok, if(digit == 10, do: "X", else: to_string(digit))}
    else
      {:error, :invalid_isbn}
    end
  end

  defp isbn10_sum(<<d, rest::binary>>, weight, acc),
    do: isbn10_sum(rest, weight - 1, acc + (d - ?0) * weight)

  defp isbn10_sum(<<>>, _weight, acc), do: acc

  defp calculate_isbn13_checkdigit(isbn) do
    normalized = normalize(isbn)

    if String.length(normalized) in 11..13 do
      nsum = isbn13_sum(binary_part(normalized, 0, min(12, byte_size(normalized))), 0, 0)
      digit = 10 - Integer.mod(nsum, 10)
      {:ok, to_string(if(digit == 10, do: 0, else: digit))}
    else
      {:error, :invalid_isbn}
    end
  end

  defp isbn13_sum(<<d, rest::binary>>, index, acc) do
    weight = if rem(index, 2) == 0, do: 1, else: 3
    isbn13_sum(rest, index + 1, acc + (d - ?0) * weight)
  end

  defp isbn13_sum(<<>>, _index, acc), do: acc

  defp prepare_isbn_13(isbn) do
    if isbn10?(isbn) do
      case isbn10_to_13(isbn) do
        {:ok, converted} -> converted
        {:error, _} -> nil
      end
    else
      normalize(isbn)
    end
  end

  @doc """
  Returns the type of the ISBN: `:isbn10`, `:isbn13`, or `:invalid`.

  Does not require hyphens or any particular formatting — normalization is applied first.

  ## Examples

      iex> Exisbn.isbn_type("978-85-359-0277-8")
      :isbn13
      iex> Exisbn.isbn_type("85-359-0277-5")
      :isbn10
      iex> Exisbn.isbn_type("invalid")
      :invalid
      iex> Exisbn.isbn_type("9788535902778")
      :isbn13

  """
  @spec isbn_type(String.t()) :: :isbn10 | :isbn13 | :invalid
  def isbn_type(isbn) when is_bitstring(isbn) do
    normalized = normalize(isbn)
    len = String.length(normalized)

    cond do
      len == 10 and checkdigit_correct_for_normalized?(normalized) -> :isbn10
      len == 13 and checkdigit_correct_for_normalized?(normalized) -> :isbn13
      true -> :invalid
    end
  end

  def isbn_type(_), do: :invalid

  @doc """
  Returns the GS1 prefix group (`"978"` or `"979"`) of a valid ISBN-13.

  Returns `{:error, :invalid_isbn}` if the input is not a valid ISBN-13.
  Accepts hyphenated or plain ISBN-13 strings. ISBN-10 is not accepted —
  use `isbn10_to_13/1` first if needed.

  ## Examples

      iex> Exisbn.isbn13_prefix_group("9788535902778")
      {:ok, "978"}
      iex> Exisbn.isbn13_prefix_group("9798893031355")
      {:ok, "979"}
      iex> Exisbn.isbn13_prefix_group("978-85-359-0277-8")
      {:ok, "978"}
      iex> Exisbn.isbn13_prefix_group("85-359-0277-5")
      {:error, :invalid_isbn}
      iex> Exisbn.isbn13_prefix_group("str")
      {:error, :invalid_isbn}

  """
  @spec isbn13_prefix_group(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def isbn13_prefix_group(isbn) when is_bitstring(isbn) do
    normalized = normalize(isbn)

    if String.length(normalized) == 13 and checkdigit_correct_for_normalized?(normalized) do
      {:ok, String.slice(normalized, 0, 3)}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Same as `isbn13_prefix_group/1`, but raises exception.

  ## Examples

      iex> Exisbn.isbn13_prefix_group!("9788535902778")
      "978"
      iex> Exisbn.isbn13_prefix_group!("9798893031355")
      "979"
      iex> Exisbn.isbn13_prefix_group!("str")
      ** (ArgumentError) Invalid ISBN

  """
  @spec isbn13_prefix_group!(String.t()) :: String.t()
  def isbn13_prefix_group!(isbn) when is_bitstring(isbn) do
    case isbn13_prefix_group(isbn) do
      {:ok, group} -> group
      {:error, reason} -> raise(ArgumentError, format_error(reason))
    end
  end

  @doc """
  Normalizes an ISBN string by removing separators and uppercasing.

  Strips hyphens, spaces, and any non-digit characters, then upcases the
  result so the check-digit `x` becomes `X`. Returns a bare digit string
  (plus optional trailing `X` for ISBN-10).

  This function does **not** validate the ISBN — use `valid?/1` for that.

  ## Examples

      iex> Exisbn.normalize("978-85-359-0277-8")
      "9788535902778"

      iex> Exisbn.normalize("85-359-0277-5")
      "8535902775"

      iex> Exisbn.normalize("978 85 359 0277 8")
      "9788535902778"

      iex> Exisbn.normalize("887385107x")
      "887385107X"

      iex> Exisbn.normalize("9788535902778")
      "9788535902778"

  """
  @spec normalize(String.t()) :: String.t()
  def normalize(isbn) when is_bitstring(isbn) do
    isbn
    |> String.upcase()
    |> String.replace(@non_isbn_chars, "")
  end

  def normalize(_), do: ""

  defp correct_normalized_length?(normalized) do
    len = String.length(normalized)
    len == 10 or len == 13
  end

  defp checkdigit_correct_for_normalized?(normalized) do
    result =
      if String.length(normalized) == 10 do
        calculate_isbn10_checkdigit(normalized)
      else
        calculate_isbn13_checkdigit(normalized)
      end

    case result do
      {:ok, digit} -> digit == String.last(normalized)
      {:error, _} -> false
    end
  end

  defp isbn10?(isbn) do
    length = isbn |> normalize() |> String.length()
    length == 10
  end

  defp correct?(isbn) do
    normalized = normalize(isbn)
    correct_normalized_length?(normalized) and checkdigit_correct_for_normalized?(normalized)
  end

  defp drop_chars(str, amount) do
    String.slice(str, amount..String.length(str))
  end

  defp search_prefix_range(gs1_prefix, body) do
    dataset = Regions.dataset()

    Enum.find_value(0..5, fn len ->
      key = "#{gs1_prefix}-#{String.slice(body, 0, len + 1)}"
      if Map.has_key?(dataset, key), do: key
    end)
  end

  defp fetch_body(isbn, prefix) do
    isbn
    |> drop_chars(String.length(prefix) - 1)
    |> String.slice(0..-2//1)
  end

  defp fetch_info(isbn) do
    case fetch_prefix(isbn) do
      {:ok, prefix} -> Map.get(Regions.dataset(), prefix)
      {:error, _} -> nil
    end
  end

  defp hyphenate_isbn13(isbn) when is_bitstring(isbn) do
    isbn13 = normalize(isbn)

    with {:ok, prefix} <- fetch_prefix(isbn13),
         {:ok, registrant} <- registrant_with_prefix(isbn13, prefix),
         {:ok, publication} <-
           publication_with_prefix_and_registrant(isbn13, prefix, registrant) do
      {:ok, Enum.join([prefix, registrant, publication, String.last(isbn13)], "-")}
    end
  end

  defp hyphenate_isbn10(isbn) when is_bitstring(isbn) do
    with {:ok, isbn13} <- isbn10_to_13(isbn),
         {:ok, full_prefix} <- fetch_prefix(isbn13),
         {:ok, registrant} <- registrant_with_prefix(isbn13, full_prefix),
         {:ok, publication} <-
           publication_with_prefix_and_registrant(isbn13, full_prefix, registrant) do
      isbn10_prefix = String.split(full_prefix, "-", trim: true) |> List.last()
      checkdigit = isbn |> normalize() |> String.last()

      {:ok, Enum.join([isbn10_prefix, registrant, publication, checkdigit], "-")}
    end
  end

  # Finds the registrant element given a pre-computed prefix and ISBN-13, avoiding
  # a redundant fetch_prefix call compared to the public fetch_registrant_element/1.
  defp registrant_with_prefix(isbn13, prefix) do
    ranges =
      case Map.get(Regions.dataset(), prefix) do
        nil -> []
        info -> Map.get(info, "ranges", [])
      end

    body = fetch_body(isbn13, prefix)

    if Enum.empty?(ranges) do
      {:error, :unknown_publisher}
    else
      Enum.reduce_while(ranges, {:error, :unknown_publisher}, fn {beg, ending, len}, _ ->
        range_part = String.slice(body, 0, len)
        area = String.to_integer(range_part)

        if beg <= area && area <= ending,
          do: {:halt, {:ok, range_part}},
          else: {:cont, {:error, :unknown_publisher}}
      end)
    end
  end

  # Derives the publication element given pre-computed prefix and registrant,
  # avoiding redundant lookups compared to the public fetch_publication_element/1.
  defp publication_with_prefix_and_registrant(isbn13, prefix, registrant) do
    body = fetch_body(isbn13, normalize(prefix))
    {:ok, drop_chars(body, String.length(registrant) + 1)}
  end

  defp format_error(:invalid_isbn), do: "Invalid ISBN"
  defp format_error(:unknown_group), do: "Unknown registration group"
  defp format_error(:unknown_publisher), do: "Unknown publisher"
  defp format_error(:no_isbn10_equivalent), do: "No ISBN-10 equivalent"
end
