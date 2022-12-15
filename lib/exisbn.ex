defmodule Exisbn do
  @moduledoc """
  Documentation for `Exisbn`.
  """

  @doc """
  Checks if string corresponds isbn10 format (without hyphens!).

  ## Examples

      iex> Exisbn.isbn10?("0545010225")
      true
      iex> Exisbn.isbn10?("string")
      false
      iex> Exisbn.isbn10?("0545010")
      false

  """
  @spec isbn10?(String.t()) :: boolean()
  def isbn10?(isbn) do
    length = isbn |> normalize() |> String.length()
    length == 10
  end

  @doc """
  Takes an ISBN 10 code as string, returns its check digit.

  ## Examples

    iex> Exisbn.isbn10_checkdigit("85-359-0277")
    5
    iex> Exisbn.isbn10?("85-359-02775")
    true
    iex> Exisbn.isbn10_checkdigit("5-02-013850")
    9
    iex> Exisbn.isbn10?("5-02-0138509")
    true
    iex> Exisbn.isbn10_checkdigit("0str")
    {:error, "Incorrect ISBN 10"}
  """

  def isbn10_checkdigit(isbn) do
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

      if digit == 10, do: {:error, "Incorrect ISBN 10"}, else: digit
    else
      {:error, "Incorrect ISBN 10"}
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

  defp to_int(char) do
    {number, _} = Integer.parse(char)
    number
  end

  defp is_digit(ch) do
    Enum.member?(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], ch)
  end
end
