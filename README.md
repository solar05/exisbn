[![CI](https://github.com/solar05/exisbn/actions/workflows/elixir.yml/badge.svg)](https://github.com/solar05/exisbn/actions/workflows/elixir.yml)
[![codecov](https://codecov.io/gh/solar05/exisbn/graph/badge.svg?token=BJ232PTWT7)](https://codecov.io/gh/solar05/exisbn)
![Hex.pm](https://img.shields.io/hexpm/v/exisbn)
![Hex.pm](https://img.shields.io/hexpm/l/exisbn)

# Exisbn

A lightweight Elixir library for working with ISBN (International Standard Book Number) identifiers. Supports ISBN-10 and ISBN-13 validation, conversion, and metadata extraction.

## Features

- **Validation** — Check if an ISBN-10 or ISBN-13 is valid
- **Type Detection** — Identify whether an ISBN is ISBN-10, ISBN-13, or invalid
- **Conversion** — Convert between ISBN-10 and ISBN-13 formats
- **Hyphenation** — Format ISBNs with correct hyphens
- **Check Digits** — Calculate and verify ISBN check digits
- **Metadata** — Extract publisher zones, country codes, registrant elements, and publication elements
- **Normalization** — Strip separators and canonicalize ISBN strings
- **Metadata** — Fetch all ISBN metadata in a single call
- **Flexible Input** — Accepts ISBNs with or without hyphens

## Installation

Add `exisbn` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exisbn, "~> 2.2"}
  ]
end
```

Then run `mix deps.get` to fetch the dependency.

## Quick Start

```elixir
# Validate an ISBN
Exisbn.valid?("978-85-359-0277-8")
# => true

# Detect ISBN type
Exisbn.isbn_type("978-85-359-0277-8")
# => :isbn13
Exisbn.isbn_type("85-359-0277-5")
# => :isbn10

# Convert ISBN-10 to ISBN-13
Exisbn.isbn10_to_13("85-359-0277-5")
# => {:ok, "9788535902778"}

# Hyphenate an ISBN
Exisbn.hyphenate("9788535902778")
# => {:ok, "978-85-359-0277-8"}

# Get the publisher zone
Exisbn.publisher_zone("9788535902778")
# => {:ok, "Brazil"}

# Get the ISO 3166-1 alpha-2 country code
Exisbn.publisher_country_code("9788535902778")
# => {:ok, "BR"}

# Get the GS1 prefix group (978 or 979)
Exisbn.isbn13_prefix_group("9788535902778")
# => {:ok, "978"}

# Fetch all metadata at once
Exisbn.fetch_metadata("9788535902778")
# => {:ok, %{prefix: "978-85", zone: "Brazil", country_code: "BR",
#            registrant: "359", publication: "0277", checkdigit: "8"}}
```

### Validation Functions

#### `isbn_type(isbn)` — Detect ISBN type

Returns `:isbn10`, `:isbn13`, or `:invalid`. Never raises.

```elixir
Exisbn.isbn_type("978-85-359-0277-8")   # => :isbn13
Exisbn.isbn_type("85-359-0277-5")       # => :isbn10
Exisbn.isbn_type("invalid")             # => :invalid
```

#### `valid?(isbn)` — Validate ISBN

Returns `true` if the ISBN is valid (correct format, length, and check digit), `false` otherwise.

```elixir
# Valid ISBNs
Exisbn.valid?("978-5-12345-678-1")    # => true
Exisbn.valid?("85-359-0277-5")        # => true
Exisbn.valid?("9788535902778")        # => true

# Invalid ISBNs
Exisbn.valid?("978-5-12345-678")      # => false (invalid check digit)
Exisbn.valid?("85-359-0277")          # => false (incomplete)
Exisbn.valid?("invalid")              # => false
```

#### `checkdigit_correct?(isbn)` — Verify check digit only

Returns `true` if the ISBN's check digit is correct, `false` otherwise. Does not validate format or length comprehensively.

```elixir
Exisbn.checkdigit_correct?("85-359-0277-5")      # => true
Exisbn.checkdigit_correct?("978-5-12345-678-1")  # => true
Exisbn.checkdigit_correct?("978-5-12345-678")    # => false
```

#### `correct_hyphens?(isbn)` — Check formatting

Returns `true` if the ISBN is valid and has correct hyphenation, `false` otherwise.

```elixir
Exisbn.correct_hyphens?("978-85-359-0277-8")     # => true
Exisbn.correct_hyphens?("97-8853590277-8")       # => false (incorrect hyphens)
Exisbn.correct_hyphens?("0-306-40615-2")         # => true
Exisbn.correct_hyphens?("03-064-06152")          # => false
```

### Check Digit Functions

#### `isbn10_checkdigit(isbn)` / `isbn10_checkdigit!(isbn)` — Calculate ISBN-10 check digit

Returns the check digit for an ISBN-10. The check digit may be a digit or `X` (representing 10).

```elixir
# Standard form
Exisbn.isbn10_checkdigit("85-359-0277")    # => {:ok, "5"}
Exisbn.isbn10_checkdigit("5-02-013850")    # => {:ok, "9"}
Exisbn.isbn10_checkdigit("887385107")      # => {:ok, "X"}
Exisbn.isbn10_checkdigit("0str")           # => {:error, :invalid_isbn}

# Bang form (raises on error)
Exisbn.isbn10_checkdigit!("85-359-0277")   # => "5"
Exisbn.isbn10_checkdigit!("invalid")       # ** (ArgumentError) Invalid ISBN
```

#### `isbn13_checkdigit(isbn)` / `isbn13_checkdigit!(isbn)` — Calculate ISBN-13 check digit

Returns the check digit for an ISBN-13 (always a digit 0-9).

```elixir
# Standard form
Exisbn.isbn13_checkdigit("978-5-12345-678")     # => {:ok, "1"}
Exisbn.isbn13_checkdigit("978-0-306-40615")     # => {:ok, "7"}
Exisbn.isbn13_checkdigit("0str")                # => {:error, :invalid_isbn}

# Bang form
Exisbn.isbn13_checkdigit!("978-5-12345-678")    # => "1"
```

### Conversion Functions

#### `isbn10_to_13(isbn)` / `isbn10_to_13!(isbn)` — Convert ISBN-10 to ISBN-13

Converts a valid ISBN-10 to ISBN-13 format by prefixing `978` and recalculating the check digit.

```elixir
# Standard form
Exisbn.isbn10_to_13("85-359-0277-5")       # => {:ok, "9788535902778"}
Exisbn.isbn10_to_13("0306406152")          # => {:ok, "9780306406157"}
Exisbn.isbn10_to_13("invalid")             # => {:error, :invalid_isbn}

# Bang form
Exisbn.isbn10_to_13!("85-359-0277-5")      # => "9788535902778"
Exisbn.isbn10_to_13!("invalid")            # ** (ArgumentError) Invalid ISBN

# Verify conversion result
Exisbn.valid?("9788535902778")             # => true
```

#### `isbn13_to_10(isbn)` / `isbn13_to_10!(isbn)` — Convert ISBN-13 to ISBN-10

Converts a valid ISBN-13 to ISBN-10 format by removing the prefix and recalculating the check digit. Only works for ISBN-13s with `978` prefix.

```elixir
# Standard form
Exisbn.isbn13_to_10("9788535902778")       # => {:ok, "8535902775"}
Exisbn.isbn13_to_10("9780306406157")       # => {:ok, "0306406152"}
Exisbn.isbn13_to_10("str")                 # => {:error, :invalid_isbn}

# Bang form
Exisbn.isbn13_to_10!("9788535902778")      # => "8535902775"
Exisbn.isbn13_to_10!("invalid")            # ** (ArgumentError) Invalid ISBN

# Verify conversion result
Exisbn.valid?("8535902775")                # => true
```

**Note:** ISBN-13s starting with `979` cannot be converted to ISBN-10 and will return `{:error, :no_isbn10_equivalent}`.
The bang form raises `** (ArgumentError) No ISBN-10 equivalent` in this case.

### Formatting Functions

#### `hyphenate(isbn)` / `hyphenate!(isbn)` — Format ISBN with hyphens

Returns the ISBN formatted with correct hyphens according to its publisher zone.

```elixir
# Standard form
Exisbn.hyphenate("9788535902778")          # => {:ok, "978-85-359-0277-8"}
Exisbn.hyphenate("0306406152")             # => {:ok, "0-306-40615-2"}
Exisbn.hyphenate("str")                    # => {:error, :invalid_isbn}

# Bang form
Exisbn.hyphenate!("9788535902778")         # => "978-85-359-0277-8"
Exisbn.hyphenate!("0306406152")            # => "0-306-40615-2"
```

#### `isbn13_prefix_group(isbn)` / `isbn13_prefix_group!(isbn)` — Get GS1 prefix group

Returns `"978"` or `"979"` for a valid ISBN-13. Returns `{:error, :invalid_isbn}` for anything
that is not a valid ISBN-13 (including valid ISBN-10s — use `isbn10_to_13/1` first if needed).

```elixir
# Standard form
Exisbn.isbn13_prefix_group("9788535902778")    # => {:ok, "978"}
Exisbn.isbn13_prefix_group("9798893031355")    # => {:ok, "979"}
Exisbn.isbn13_prefix_group("978-85-359-0277-8")# => {:ok, "978"}
Exisbn.isbn13_prefix_group("85-359-0277-5")    # => {:error, :invalid_isbn}  # ISBN-10

# Bang form
Exisbn.isbn13_prefix_group!("9788535902778")   # => "978"
Exisbn.isbn13_prefix_group!("str")             # ** (ArgumentError) Invalid ISBN
```

Useful for quickly checking whether an ISBN-13 can be converted to ISBN-10 (only `"978"` prefix):

```elixir
case Exisbn.isbn13_prefix_group(isbn) do
  {:ok, "978"} -> Exisbn.isbn13_to_10(isbn)
  {:ok, "979"} -> {:error, :no_isbn10_equivalent}
  error        -> error
end
```

### Metadata Extraction Functions

#### `fetch_prefix(isbn)` / `fetch_prefix!(isbn)` — Get ISBN prefix (group identifier)

Returns the ISBN prefix including group identifier (e.g., `978-85` for Brazil).

```elixir
# Standard form
Exisbn.fetch_prefix("9788535902778")       # => {:ok, "978-85"}
Exisbn.fetch_prefix("2-1234-5680-2")       # => {:ok, "978-2"}
Exisbn.fetch_prefix("str")                 # => {:error, :invalid_isbn}

# Bang form
Exisbn.fetch_prefix!("9788535902778")      # => "978-85"
Exisbn.fetch_prefix!("str")               # ** (ArgumentError) Invalid ISBN
Exisbn.fetch_prefix!("9799012345674")      # ** (ArgumentError) Unknown registration group
```

#### `publisher_zone(isbn)` / `publisher_zone!(isbn)` — Get publisher zone/country

Returns the geographic zone or language group associated with the ISBN prefix.

```elixir
# Standard form
Exisbn.publisher_zone("9788535902778")     # => {:ok, "Brazil"}
Exisbn.publisher_zone("2-1234-5680-2")     # => {:ok, "French language"}
Exisbn.publisher_zone("str")               # => {:error, :invalid_isbn}

# Bang form
Exisbn.publisher_zone!("9788535902778")    # => "Brazil"
Exisbn.publisher_zone!("2-1234-5680-2")    # => "French language"
```

#### `publisher_country_code(isbn)` / `publisher_country_code!(isbn)` — Get ISO 3166-1 alpha-2 country code

Returns the two-letter ISO 3166-1 alpha-2 country code for the ISBN's registration group.
Returns `{:ok, nil}` for groups that cover multiple countries or language areas
(e.g. `978-0`/`978-1` — English language, `978-2` — French language, `978-3` — German language,
`978-5` — former U.S.S.R., `978-92` — International NGO Publishers, `978-976` — Caribbean Community).

```elixir
# Standard form
Exisbn.publisher_country_code("9788535902778")     # => {:ok, "BR"}
Exisbn.publisher_country_code("9784065393987")     # => {:ok, "JP"}
Exisbn.publisher_country_code("9780306406157")     # => {:ok, nil}  # English language group
Exisbn.publisher_country_code("str")               # => {:error, :invalid_isbn}

# Bang form
Exisbn.publisher_country_code!("9788535902778")    # => "BR"
Exisbn.publisher_country_code!("9784065393987")    # => "JP"
Exisbn.publisher_country_code!("9780306406157")    # => nil
```

#### `fetch_checkdigit(isbn)` / `fetch_checkdigit!(isbn)` — Extract check digit

Returns the check digit character from the ISBN (as a string). For ISBN-10, this may be `X`.

```elixir
# Standard form
Exisbn.fetch_checkdigit("9788535902778")   # => {:ok, "8"}
Exisbn.fetch_checkdigit("2-1234-5680-2")   # => {:ok, "2"}
Exisbn.fetch_checkdigit("887385107X")      # => {:ok, "X"}
Exisbn.fetch_checkdigit("str")             # => {:error, :invalid_isbn}

# Bang form
Exisbn.fetch_checkdigit!("9788535902778")  # => "8"
Exisbn.fetch_checkdigit!("887385107X")     # => "X"
```

#### `fetch_registrant_element(isbn)` / `fetch_registrant_element!(isbn)` — Get registrant identifier

Returns the registrant element (publisher identifier) of the ISBN.

```elixir
# Standard form
Exisbn.fetch_registrant_element("9788535902778")       # => {:ok, "359"}
Exisbn.fetch_registrant_element("978-1-86197-876-9")   # => {:ok, "86197"}
Exisbn.fetch_registrant_element("9789529351787")       # => {:ok, "93"}
Exisbn.fetch_registrant_element("str")                 # => {:error, :invalid_isbn}

# Bang form
Exisbn.fetch_registrant_element!("9788535902778")      # => "359"
Exisbn.fetch_registrant_element!("978-1-86197-876-9")  # => "86197"
Exisbn.fetch_registrant_element!("9799012345674")      # ** (ArgumentError) Unknown registration group
Exisbn.fetch_registrant_element!("9786110000000")      # ** (ArgumentError) Unknown publisher
```

#### `fetch_metadata(isbn)` / `fetch_metadata!(isbn)` — Get all metadata at once

Returns a map with all ISBN metadata in a single call. More efficient than calling individual
metadata functions separately, since the prefix and registrant lookups are performed only once.

The returned map contains:
- `prefix` — registration group prefix (e.g., `"978-85"`)
- `zone` — publisher zone or language group name
- `country_code` — ISO 3166-1 alpha-2 code, or `nil` for multi-country groups
- `registrant` — registrant (publisher) identifier
- `publication` — publication (title) identifier
- `checkdigit` — the check digit character

```elixir
# Standard form
Exisbn.fetch_metadata("9788535902778")
# => {:ok, %{prefix: "978-85", zone: "Brazil", country_code: "BR",
#            registrant: "359", publication: "0277", checkdigit: "8"}}

Exisbn.fetch_metadata("9780306406157")
# => {:ok, %{prefix: "978-0", zone: "English language", country_code: nil,
#            registrant: "306", publication: "40615", checkdigit: "7"}}

Exisbn.fetch_metadata("str")
# => {:error, :invalid_isbn}

# Bang form
Exisbn.fetch_metadata!("9788535902778")
# => %{prefix: "978-85", zone: "Brazil", country_code: "BR",
#      registrant: "359", publication: "0277", checkdigit: "8"}

Exisbn.fetch_metadata!("str")
# ** (ArgumentError) Invalid ISBN
```

Works with ISBN-10 input as well — metadata is derived from the equivalent ISBN-13,
while the check digit reflects the original ISBN-10:

```elixir
Exisbn.fetch_metadata("85-359-0277-5")
# => {:ok, %{prefix: "978-85", zone: "Brazil", country_code: "BR",
#            registrant: "359", publication: "0277", checkdigit: "5"}}
```

#### `fetch_publication_element(isbn)` / `fetch_publication_element!(isbn)` — Get publication/title identifier

Returns the publication element (title/publication identifier) of the ISBN.

```elixir
# Standard form
Exisbn.fetch_publication_element("978-1-86197-876-9")  # => {:ok, "876"}
Exisbn.fetch_publication_element("9789529351787")      # => {:ok, "5178"}
Exisbn.fetch_publication_element("str")                # => {:error, :invalid_isbn}

# Bang form
Exisbn.fetch_publication_element!("978-1-86197-876-9") # => "876"
Exisbn.fetch_publication_element!("9789529351787")     # => "5178"
```

### Normalization Functions

#### `normalize(isbn)` — Strip separators and canonicalize

Returns a bare string of digits (plus `X` for ISBN-10 check digit). Removes
hyphens, spaces, and any non-digit characters, and upcases the result.

This function does **not** validate the ISBN. Use `valid?/1` for validation.

```elixir
Exisbn.normalize("978-85-359-0277-8")   # => "9788535902778"
Exisbn.normalize("85-359-0277-5")       # => "8535902775"
Exisbn.normalize("978 85 359 0277 8")   # => "9788535902778"
Exisbn.normalize("887385107x")          # => "887385107X"
Exisbn.normalize("9788535902778")       # => "9788535902778"
```

Useful for normalizing ISBNs before storing in a database or comparing values.

## Input Handling

The library is flexible with input formatting. Validation operates on the normalized form
(digits + optional trailing `X`), so any separator character is accepted as long as the
extracted digits form a valid ISBN.

```elixir
# All these are equivalent:
Exisbn.valid?("9788535902778")             # => true
Exisbn.valid?("978-85-359-0277-8")         # => true
Exisbn.valid?("978 85 359 0277 8")         # => true
Exisbn.valid?("978.85.359.0277.8")         # => true  (dots work too)
Exisbn.valid?("978.853590277.8")           # => true  (any grouping)

# ISBN-10 with check digit X
Exisbn.valid?("887385107X")                # => true (uppercase X)
Exisbn.valid?("887385107x")                # => true (lowercase x is normalized to X)
```

Normalization strips everything except digits and `X`, then upcases the result.
`normalize/1` can be used explicitly before storing or comparing ISBNs.

## ISBN Specifications

### ISBN-10

- 10 characters total
- Last character may be a digit (0-9) or `X` (representing 10)
- Uses modulo 11 checksum algorithm
- Convertible to ISBN-13 by prefixing `978`

### ISBN-13

- 13 digits total
- Common prefixes: `978` or `979`
- Uses modulo 10 checksum algorithm
- ISBN-13 with `978` prefix can be converted back to ISBN-10
- ISBN-13 with `979` prefix cannot be converted to ISBN-10

## Error Handling

Standard functions return tagged error tuples:

| Error atom | Meaning | Functions that can return it |
|---|---|---|
| `:invalid_isbn` | ISBN is structurally invalid (wrong length, bad check digit, non-digit chars) | all |
| `:unknown_group` | ISBN is valid but its registration group is not in the dataset | `fetch_prefix`, `publisher_zone`, `publisher_country_code`, `fetch_registrant_element`, `fetch_publication_element`, `fetch_metadata`, `hyphenate` |
| `:unknown_publisher` | Registration group is known but has no publisher ranges defined | `fetch_registrant_element`, `fetch_publication_element`, `fetch_metadata`, `hyphenate` |
| `:no_isbn10_equivalent` | ISBN-13 with `979` prefix has no ISBN-10 equivalent | `isbn13_to_10` |

```elixir
case Exisbn.publisher_zone("9799012345674") do
  {:ok, zone}               -> IO.puts("Zone: #{zone}")
  {:error, :invalid_isbn}   -> IO.puts("Invalid ISBN")
  {:error, :unknown_group}  -> IO.puts("Registration group not in dataset")
end
```

Bang functions raise `ArgumentError` with a descriptive message:

| Error atom | `ArgumentError` message |
|---|---|
| `:invalid_isbn` | `"Invalid ISBN"` |
| `:unknown_group` | `"Unknown registration group"` |
| `:unknown_publisher` | `"Unknown publisher"` |
| `:no_isbn10_equivalent` | `"No ISBN-10 equivalent"` |

```elixir
try do
  Exisbn.isbn13_to_10!("9798893031355")
rescue
  e in ArgumentError -> IO.puts(e.message)  # "No ISBN-10 equivalent"
end
```

## Examples

### Validate and format an ISBN

```elixir
isbn = "978-85-359-0277-8"

if Exisbn.valid?(isbn) do
  {:ok, formatted} = Exisbn.hyphenate(isbn)
  IO.puts("Valid ISBN: #{formatted}")
else
  IO.puts("Invalid ISBN")
end
```

### Convert and extract information

```elixir
isbn10 = "85-359-0277-5"

with {:ok, isbn13} <- Exisbn.isbn10_to_13(isbn10),
     {:ok, zone} <- Exisbn.publisher_zone(isbn13),
     {:ok, country_code} <- Exisbn.publisher_country_code(isbn13),
     {:ok, prefix} <- Exisbn.fetch_prefix(isbn13) do
  IO.puts("ISBN-10: #{isbn10}")
  IO.puts("ISBN-13: #{isbn13}")
  IO.puts("Publisher Zone: #{zone}")
  IO.puts("Country Code: #{country_code}")
  IO.puts("Prefix: #{prefix}")
else
  {:error, :invalid_isbn} -> IO.puts("Invalid ISBN")
end
```

### Find ISBN details

```elixir
isbn = "978-1-86197-876-9"

with true <- Exisbn.valid?(isbn),
     {:ok, zone} <- Exisbn.publisher_zone(isbn),
     {:ok, registrant} <- Exisbn.fetch_registrant_element(isbn),
     {:ok, publication} <- Exisbn.fetch_publication_element(isbn) do
  IO.puts("Zone: #{zone}")
  IO.puts("Registrant: #{registrant}")
  IO.puts("Publication: #{publication}")
else
  _ -> IO.puts("Could not extract ISBN details")
end
```

## Documentation

Full API documentation with more examples is available at [HexDocs](https://hexdocs.pm/exisbn/Exisbn.html).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests on [GitHub](https://github.com/solar05/exisbn).
