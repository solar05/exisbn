# AGENTS.md

## Project overview

`exisbn` is a small Elixir utility library for working with ISBN identifiers.

The library provides helpers to:

- validate ISBN-10 and ISBN-13 values;
- convert ISBN-10 to ISBN-13;
- convert ISBN-13 to ISBN-10 when possible;
- calculate ISBN check digits.

The public API is centered around the `Exisbn` module.

This repository is intentionally small. Prefer simple, explicit Elixir code over abstractions, frameworks, or additional dependencies.

## Repository layout

```text
.
├── lib/
│   └── exisbn.ex
├── test/
│   └── exisbn_test.exs
├── mix.exs
├── mix.lock
├── README.md
├── LICENSE
└── .formatter.exs
```

Important files:

- `lib/exisbn.ex` — main library implementation.
- `test/exisbn_test.exs` — ExUnit tests for ISBN behavior.
- `README.md` — public usage documentation.
- `mix.exs` — project metadata, version, dependencies, supported Elixir version.

## Development commands

Run these commands from the repository root.

Format code:

```sh
mix format
```

Run tests:

```sh
mix test
```

Compile the project:

```sh
mix compile
```

Run an interactive shell with the project loaded:

```sh
iex -S mix
```

If dependencies need to be fetched:

```sh
mix deps.get
```

## Coding guidelines

Use idiomatic Elixir.

Prefer:

- small pure functions;
- pattern matching;
- guards where they improve clarity;
- pipelines only when they make the data flow easier to read;
- clear function names;
- explicit return values.

Avoid:

- unnecessary macros;
- global state;
- processes/GenServers unless there is a strong reason;
- adding runtime dependencies;
- over-engineering;
- changing the public API casually.

This is a utility library. Keep the implementation compact and predictable.

## Public API expectations

Treat functions documented in `README.md` and public functions in `Exisbn` as part of the public API.

Before changing behavior, check:

- existing tests;
- README examples;
- function names and return values;
- compatibility with existing users.

Do not rename or remove public functions unless explicitly requested.

When adding new public functions:

- add tests;
- add `@doc` documentation;
- update `README.md` if the function is user-facing;
- keep return values consistent with the existing API style.

## ISBN domain rules

ISBN-10:

- contains 10 digits;
- the last character may be `X` or `x`, representing value `10`;
- uses the ISBN-10 checksum algorithm;
- may be convertible to ISBN-13 by prefixing `978` and recalculating the check digit.

ISBN-13:

- contains 13 digits;
- commonly starts with `978` or `979`;
- uses the ISBN-13 checksum algorithm;
- only ISBN-13 values with `978` prefix are generally convertible back to ISBN-10.

When modifying ISBN logic, preserve these rules unless the issue explicitly asks for a different behavior.

Be careful with:

- lowercase `x` in ISBN-10 check digits;
- invalid characters;
- strings containing hyphens or spaces;
- empty strings;
- `nil` inputs;
- too-short and too-long values;
- ISBN-13 values starting with `979`;
- checksum edge cases.

## Input handling

Follow the existing behavior of the library.

Before changing input normalization, inspect current tests and implementation.

If the library currently accepts formatted ISBNs with separators, keep that behavior unless explicitly asked otherwise.

If the library currently expects plain digit strings, do not silently broaden accepted input without tests and documentation.

Be explicit about whether a function accepts:

- strings only;
- integers;
- hyphenated ISBNs;
- whitespace;
- lowercase `x`;
- `nil`.

## Testing guidelines

All behavior changes must include ExUnit tests.

Use tests to cover:

- valid ISBN-10 examples;
- invalid ISBN-10 examples;
- valid ISBN-13 examples;
- invalid ISBN-13 examples;
- ISBN-10 to ISBN-13 conversion;
- ISBN-13 to ISBN-10 conversion;
- checksum calculation;
- malformed input;
- edge cases around `X` / `x`.

Run the full test suite before finishing:

```sh
mix test
```

Also run formatting:

```sh
mix format
```

Prefer focused unit tests. Do not introduce heavy test frameworks.

## Documentation guidelines

Keep documentation concise and practical.

When changing public behavior, update:

- `README.md`;
- relevant `@doc` comments;
- examples if return values or accepted input formats change.

Examples should be copy-pasteable into `iex`.

Prefer showing both successful and unsuccessful cases when documenting validators.

## Error handling

Preserve existing return-value conventions.

Do not introduce exceptions for normal validation failures unless explicitly requested.

For validation helpers, prefer boolean-style results if that is how the current API works.

For conversion helpers, preserve the existing behavior for invalid or non-convertible inputs.

If a function returns `nil`, `false`, `{:ok, value}`, or `{:error, reason}`, this must be obvious from documentation and tests.

## Compatibility

Do not raise the minimum Elixir version unless necessary.

Before making compatibility-sensitive changes:

- inspect `mix.exs`;
- keep code compatible with the declared Elixir version;
- avoid standard-library functions that are unavailable in the supported version.

If raising the minimum Elixir version is required, explain why in the commit or PR description and update CI configuration if present.

## Dependencies

This is a small utility library. Avoid adding new runtime dependencies.

Development or test dependencies should only be added when they provide clear value.

Before adding any dependency, consider whether the same result can be achieved with the Elixir standard library.

## Formatting and style

Use the repository formatter.

Run:

```sh
mix format
```

Do not manually fight the formatter.

Keep code readable and direct. Avoid clever one-liners when a clear multi-line implementation is easier to maintain.

## Pull request checklist for AI agents

Before proposing a change, verify:

- code compiles;
- tests pass with `mix test`;
- code is formatted with `mix format`;
- public API compatibility is preserved;
- README is updated when user-facing behavior changes;
- new behavior has tests;
- no unnecessary dependencies were added.

## Suggested workflow for AI agents

1. Read `README.md` to understand the intended API.
2. Read `lib/exisbn.ex` to understand implementation and return values.
3. Read `test/exisbn_test.exs` to understand expected behavior.
4. Make the smallest change that satisfies the task.
5. Add or update tests.
6. Run `mix format`.
7. Run `mix test`.
8. Summarize what changed and mention any commands that could not be run.

## Common safe tasks

Good tasks for this repository include:

- adding missing tests for edge cases;
- improving documentation examples;
- clarifying accepted input formats;
- fixing checksum bugs;
- improving input normalization if requested;
- adding small helper functions with tests.

## Tasks that require extra care

Be cautious with:

- changing return values;
- changing accepted input formats;
- changing conversion behavior for `979` ISBN-13 values;
- replacing public functions;
- adding dependencies;
- broad refactors;
- changing package metadata in `mix.exs`.

## License

This project is licensed under the MIT License. Preserve the existing license header and repository license file.

