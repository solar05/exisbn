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

  defp normalize(isbn) do
    isbn
      |> String.split("", trim: true)
      |> Enum.filter(fn ch -> is_digit(ch) || ch == "X" end)
      |> Enum.join()
  end

  defp correct_length?(isbn) do
    Enum.member?([10, 13, 17], String.length(isbn))
  end

  defp is_digit(ch) do
    Enum.member?(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"], ch)
  end
end
