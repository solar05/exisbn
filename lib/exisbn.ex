defmodule Exisbn do
  require Integer

  alias Exisbn.Regions

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
      nsum =
        isbn
        |> normalize()
        |> String.slice(0..8)
        |> String.split("", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> Enum.with_index()
        |> Enum.map(fn {val, ind} ->
          (10 - ind) * val
        end)
        |> Enum.reduce(&+/2)

      digit = Integer.mod(11 - Integer.mod(nsum, 11), 11)

      result = if digit == 10, do: "X", else: to_string(digit)
      {:ok, result}
    else
      {:error, :invalid_isbn}
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
      nsum =
        isbn
        |> normalize()
        |> String.slice(0..11)
        |> String.split("", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> Enum.with_index()
        |> Enum.map(fn {val, ind} ->
          if Integer.is_odd(ind), do: val * 3, else: val
        end)
        |> Enum.reduce(&+/2)

      digit = 10 - Integer.mod(nsum, 10)

      result = if digit == 10, do: 0, else: digit
      {:ok, to_string(result)}
    else
      {:error, :invalid_isbn}
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
  def valid?(isbn) do
    Enum.all?([
      correct_length?(isbn),
      without_incorrect_chars?(isbn),
      checkdigit_correct?(isbn)
    ])
  end

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
  Takes an ISBN 13 and converts it to ISBN 10.

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
  """
  @spec isbn13_to_10(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def isbn13_to_10(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      first_chars =
        isbn
        |> normalize()
        |> drop_chars(3)
        |> String.slice(0..8)

      {:ok, checkdigit} = isbn10_checkdigit(first_chars)
      {:ok, "#{first_chars}#{checkdigit}"}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Takes an ISBN and returns its publisher zone.

  ## Examples

      iex> Exisbn.publisher_zone("9788535902778")
      {:ok, "Brazil"}
      iex> Exisbn.publisher_zone("2-1234-5680-2")
      {:ok, "French language"}
      iex> Exisbn.publisher_zone("str")
      {:error, :invalid_isbn}
  """
  @spec publisher_zone(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def publisher_zone(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn =
        if isbn10?(isbn) do
          {:ok, converted} = isbn10_to_13(isbn)
          converted
        else
          normalize(isbn)
        end

      {:ok, Map.get(fetch_info(prepared_isbn), "name")}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Takes an ISBN and returns its prefix.

  ## Examples

      iex> Exisbn.fetch_prefix("9788535902778")
      {:ok, "978-85"}
      iex> Exisbn.fetch_prefix("2-1234-5680-2")
      {:ok, "978-2"}
      iex> Exisbn.fetch_prefix("str")
      {:error, :invalid_isbn}
  """
  @spec fetch_prefix(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def fetch_prefix(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn =
        if isbn10?(isbn) do
          {:ok, result} = isbn10_to_13(isbn)
          result
        else
          normalize(isbn)
        end

      {:ok, fetch_prefix(String.slice(prepared_isbn, 0..2), drop_chars(prepared_isbn, 3), 0)}
    else
      {:error, :invalid_isbn}
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
      {:ok, String.last(isbn)}
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Takes an ISBN and returns its registrant element.

  ## Examples

      iex> Exisbn.fetch_registrant_element("9788535902778")
      {:ok, "359"}
      iex> Exisbn.fetch_registrant_element("978-1-86197-876-9")
      {:ok, "86197"}
      iex> Exisbn.fetch_registrant_element("9789529351787")
      {:ok, "93"}
      iex> Exisbn.fetch_registrant_element("str")
      {:error, :invalid_isbn}
  """
  @spec fetch_registrant_element(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def fetch_registrant_element(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn =
        if isbn10?(isbn) do
          {:ok, translated} = isbn10_to_13(isbn)
          translated
        else
          normalize(isbn)
        end

      {:ok, prefix} = fetch_prefix(prepared_isbn)
      ranges = fetch_ranges(prepared_isbn)

      body = fetch_body(prepared_isbn, prefix)

      Enum.reduce_while(ranges, "", fn range, _ ->
        beg = String.to_integer(List.first(range))
        ending = String.to_integer(List.last(range))
        length = String.length(List.last(range)) - 1
        range_part = String.slice(body, 0..length)
        area = String.to_integer(range_part)

        if beg <= area && area <= ending,
          do: {:halt, {:ok, range_part}},
          else: {:cont, {:error, :invalid_isbn}}
      end)
    else
      {:error, :invalid_isbn}
    end
  end

  @doc """
  Takes an ISBN and returns its publication element.

  ## Examples

      iex> Exisbn.fetch_publication_element("978-1-86197-876-9")
      {:ok, "876"}
      iex> Exisbn.fetch_publication_element("9789529351787")
      {:ok, "5178"}
      iex> Exisbn.fetch_publication_element("str")
      {:error, :invalid_isbn}
  """
  @spec fetch_publication_element(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def fetch_publication_element(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      prepared_isbn =
        if isbn10?(isbn) do
          {:ok, converted} = isbn10_to_13(isbn)
          converted
        else
          normalize(isbn)
        end

      {:ok, prefix} = fetch_prefix(prepared_isbn)
      normalized_prefix = normalize(prefix)
      body = fetch_body(prepared_isbn, normalized_prefix)
      {:ok, registrant} = fetch_registrant_element(prepared_isbn)

      {:ok, drop_chars(body, String.length(registrant) + 1)}
    else
      {:error, :invalid_isbn}
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
  @spec hyphenate(String.t()) :: {:ok, String.t()} | {:error, :invalid_isbn}
  def hyphenate(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      result = if isbn10?(isbn), do: hyphenate_isbn10(isbn), else: hyphenate_isbn13(isbn)
      {:ok, result}
    else
      {:error, :invalid_isbn}
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
    if correct?(isbn) do
      case hyphenate(isbn) do
        {:ok, hyphenated} -> isbn == hyphenated
        {:error, _} -> false
      end
    else
      false
    end
  end

  defp normalize(isbn) do
    isbn
    |> String.split("", trim: true)
    |> Enum.filter(fn ch -> is_digit(ch) || ch == "X" end)
    |> Enum.join()
  end

  defp correct_length?(isbn) do
    size = String.length(isbn)

    size == 10 || size == 13 || size == 17
  end

  defp without_incorrect_chars?(isbn) do
    isbn
    |> normalize()
    |> correct_length?()
  end

  defp isbn10?(isbn) do
    length = isbn |> normalize() |> String.length()
    length == 10
  end

  defp correct?(isbn) do
    valid?(normalize(isbn))
  end

  defp drop_chars(str, amount) do
    String.slice(str, amount..String.length(str))
  end

  defp is_digit(ch) do
    String.contains?("0123456789", ch)
  end

  defp fetch_prefix(prefix, body, search_length) do
    search_prefix = "#{prefix}-#{String.slice(body, 0..search_length)}"

    if Map.has_key?(Regions.dataset(), search_prefix) do
      search_prefix
    else
      fetch_prefix(prefix, body, search_length + 1)
    end
  end

  defp fetch_body(isbn, prefix) do
    isbn
    |> drop_chars(String.length(prefix) - 1)
    |> String.reverse()
    |> drop_chars(1)
    |> String.reverse()
  end

  defp fetch_info(isbn) do
    {:ok, prefix} = fetch_prefix(isbn)
    Map.get(Regions.dataset(), prefix)
  end

  defp fetch_ranges(isbn) do
    Map.get(fetch_info(isbn), "ranges")
  end

  defp hyphenate_isbn13(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      {:ok, prefix} = fetch_prefix(isbn)
      {:ok, registrant_element} = fetch_registrant_element(isbn)
      {:ok, publication_element} = fetch_publication_element(isbn)
      {:ok, checkdigit} = fetch_checkdigit(isbn)

      Enum.join(
        [
          prefix,
          registrant_element,
          publication_element,
          checkdigit
        ],
        "-"
      )
    else
      nil
    end
  end

  defp hyphenate_isbn10(isbn) when is_bitstring(isbn) do
    if correct?(isbn) do
      {:ok, converted} = isbn10_to_13(isbn)
      {:ok, full_prefix} = fetch_prefix(converted)
      {:ok, registrant_element} = fetch_registrant_element(isbn)
      {:ok, publication_element} = fetch_publication_element(isbn)
      {:ok, checkdigit} = fetch_checkdigit(isbn)

      isbn10_prefix = String.split(full_prefix, "-", trim: true) |> List.last()

      Enum.join(
        [
          isbn10_prefix,
          registrant_element,
          publication_element,
          checkdigit
        ],
        "-"
      )
    else
      nil
    end
  end
end
