[![CI](https://github.com/solar05/exisbn/actions/workflows/elixir.yml/badge.svg)](https://github.com/solar05/exisbn/actions/workflows/elixir.yml)
![Hex.pm](https://img.shields.io/hexpm/v/exisbn)
![Hex.pm](https://img.shields.io/hexpm/l/exisbn)
# Exisbn

ISBN utility library for Elixir.

## Installation

The package [available in Hex](https://hex.pm/packages/exisbn) and can be installed
by adding `exisbn` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exisbn, "~> 2.1"}
  ]
end
```

Documentation with examples can be found at [HexDocs.](https://hexdocs.pm/exisbn/Exisbn.html)

### Usage

Full list of examples presented at [documentation page.](https://hexdocs.pm/exisbn/Exisbn.html)

Hyphens:
```elixir
Exisbn.hyphenate("9788535902778")
{:ok, "978-85-359-0277-8"}

Exisbn.hyphenate("0306406152")
{:ok, "0-306-40615-2"}

Exisbn.hyphenate("str")
{:error, :invalid_isbn}
```

Validations:
```elixir
Exisbn.valid?("978-5-12345-678-1")
true

Exisbn.valid?("978-5-12345-678")
false

Exisbn.valid?("85-359-0277-5")
true

Exisbn.valid?("85-359-0277")
false

Exisbn.correct_hyphens?("978-85-359-0277-8")
true
Exisbn.correct_hyphens?("97-8853590277-8")
false
Exisbn.correct_hyphens?("0-306-40615-2")
true
Exisbn.correct_hyphens?("03-064-06152")
false

Exisbn.checkdigit_correct?("85-359-0277-5")
true
Exisbn.checkdigit_correct?("978-5-12345-678-1")
true
Exisbn.checkdigit_correct?("978-5-12345-678")
false
```

Additional info:
```elixir
Exisbn.publisher_zone("9788535902778")
{:ok, "Brazil"}
Exisbn.publisher_zone("2-1234-5680-2")
{:ok, "French language"}
Exisbn.publisher_zone("str")
{:error, :invalid_isbn}

Exisbn.fetch_registrant_element("9788535902778")
{:ok, "359"}
Exisbn.fetch_registrant_element("978-1-86197-876-9")
{:ok, "86197"}

Exisbn.fetch_publication_element("978-1-86197-876-9")
{:ok, "876"}
Exisbn.fetch_publication_element("9789529351787")
{:ok, "5178"}

Exisbn.fetch_prefix("9788535902778")
{:ok, "978-85"}
Exisbn.fetch_prefix("2-1234-5680-2")
{:ok, "978-2"}

Exisbn.fetch_checkdigit("9788535902778")
{:ok, 8}
Exisbn.fetch_checkdigit("2-1234-5680-2")
{:ok, 2}
```
