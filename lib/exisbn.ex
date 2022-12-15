defmodule Exisbn do
  require Integer

  @moduledoc """
  Documentation for `Exisbn`.
  """

  @doc """
  Takes an ISBN 10 code as string, returns its check digit.

  ## Examples

      iex> Exisbn.isbn10_checkdigit("85-359-0277")
      5
      iex> Exisbn.isbn10_checkdigit("5-02-013850")
      9
      iex> Exisbn.isbn10_checkdigit("0str")
      nil
  """
  @spec isbn10_checkdigit(String.t()) :: nil | <<_::8>> | integer
  def isbn10_checkdigit(isbn) when is_bitstring(isbn) do
    if String.length(normalize(isbn)) in 8..10 do
      nsum =
        isbn
        |> normalize()
        |> String.slice(0..8)
        |> String.split("", trim: true)
        |> Enum.map(&to_int/1)
        |> Enum.with_index()
        |> Enum.map(fn {val, ind} ->
          (10 - ind) * val
        end)
        |> Enum.reduce(&+/2)

      digit = Integer.mod(11 - Integer.mod(nsum, 11), 11)

      if digit == 10, do: "X", else: digit
    else
      nil
    end
  end

  @doc """
  Takes an ISBN 13 code as string, returns its check digit.

  ## Examples

      iex> Exisbn.isbn13_checkdigit("978-5-12345-678")
      1
      iex> Exisbn.isbn13_checkdigit("978-0-306-40615")
      7
      iex> Exisbn.isbn13_checkdigit("0str")
      nil
  """
  @spec isbn13_checkdigit(binary) :: nil | integer
  def isbn13_checkdigit(isbn) when is_bitstring(isbn) do
    if String.length(normalize(isbn)) in 11..13 do
      nsum =
        isbn
        |> normalize()
        |> String.slice(0..11)
        |> String.split("", trim: true)
        |> Enum.map(&to_int/1)
        |> Enum.with_index()
        |> Enum.map(fn {val, ind} ->
          if Integer.is_odd(ind), do: val * 3, else: val
        end)
        |> Enum.reduce(&+/2)

      digit = 10 - Integer.mod(nsum, 10)

      if digit == 10, do: 0, else: digit
    else
      nil
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

    digit =
      if String.length(normalized) == 10 do
        isbn10_checkdigit(normalized)
      else
        isbn13_checkdigit(normalized)
      end

    to_string(digit) == String.last(normalized)
  end

  @doc """
  Takes and ISBN (10 or 13) and checks its validity by checking the checkdigit, length and characters.

  ## Examples

      iex> Exisbn.valid?("978-5-12345-678-1")
      true
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
      "9788535902778"
      iex> Exisbn.valid?("9788535902778")
      true
      iex> Exisbn.isbn10_to_13("0306406152")
      "9780306406157"
      iex> Exisbn.valid?("9780306406157")
      true
      iex> Exisbn.isbn10_to_13("0-19-853453123")
      nil
  """
  @spec isbn10_to_13(String.t()) :: String.t() | nil
  def isbn10_to_13(isbn) when is_bitstring(isbn) do
    if valid?(normalize(isbn)) do
      first_chars = "978#{String.slice(normalize(isbn), 0..8)}"
      "#{first_chars}#{isbn13_checkdigit(first_chars)}"
    else
      nil
    end
  end

  defp normalize(isbn) do
    isbn
    |> String.split("", trim: true)
    |> Enum.filter(fn ch -> is_digit(ch) || ch == "X" end)
    |> Enum.join()
  end

  defp correct_length?(isbn) do
    Enum.member?([10, 13, 17], String.length(isbn))
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

  defp to_int(char) do
    {number, _} = Integer.parse(char)
    number
  end

  defp is_digit(ch) do
    Enum.member?(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], ch)
  end
end
