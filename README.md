# EctoConditionals

EctoConditionals implements a flexibly functional find_or_create and upsert behavior for Ecto models.

## Installation

The package can be installed by adding `ecto_conditionals` in `mix.exs`:

```elixir
def deps do
  [{:ecto_conditionals, "~> 0.1.0"}]
end
```

This package is available in Hex [here](https://hexdocs.pm/ecto_conditionals/),

## Basic Usage
First specify the repo you're going to use:

```elixir
use EctoConditionals, repo: MyApp.Repo
```

Then, pipe or pass the record struct to `find_or_create/1` or `upsert/1`.
These functions assume finding by id to determine whether to create or upsert.
If an id field is present in the record struct, the id field will be used
as the unique selector to determine whether to find, insert, or update.
If not present, these functions will insert a new record.

```elixir
%User{id: 1, name: "Flamel"} |> find_or_create
#=> {:ok, %User{id: 1, name: "Flamel"}}

%User{name: "Dumbledore"} |> upsert
#=> {:ok, %User{id: 2, name: "Dumbledore"}}
```

You can also specify selectors by instead using `find_or_create_by/2` or `upsert_by/2`
and passing a selector or list of selectors as the second argument.

```elixir
%User{name: "Slughorn"} |> find_or_create_by(:name)
#=> {:ok, %User{id: 3, name: "Slughorn"}}

%User{first_name: "Harry", last_name: "Potter"} |> upsert_by(:last_name)
#=> {:ok, %User{id: 4, first_name: "Harry", last_name: "Potter"}}
```

## Implementation Note
`find_or_create_by/2` is a thin wrapper piping through `find_by/2` and then `or_create/1`
`upsert_by/2` is a thin wrapper piping through `find_by/2` and then `update_or_insert/1`.
`find_or_create/1` is a thin wrapper piping through `find/1` and then `or_create/1`
and `upsert/1` is a thin wrapper piping through `find/1` and Ecto.Repo's `insert_or_update/1`.
`find/1` is also just a thin wrapper around `find_by/1` that assumes :id is the selector.
It's functions all the way down!

```elixir
%User{first_name: "Harry", last_name: "Potter"} |> find_by([:first_name, :last_name])
#=> {:found, %User{id: 4, first_name: "Harry", last_name: "Potter"}}

%User{name: "Buckbeak"} |> find_by(:name)
#=> {:not_found, %User{name: "Buckbeak"}}

# the following is equivalent
%User{id: 1} |> find_by(:id)
%User{id: 1} |> find
```

## Pro Tips
Individual functions are very flexible when used independently.
For example, try pairing Elixir's `with` construct with `find_by/2`,
which returns pattern match friendly tagged tuples such as
{:found, record_struct} or {:not_found, record_struct}.
These conditional helper functions also play well with `Ecto.Multi`.

## Common Gotchas
An `Ecto.MultipleResultsError` means your selector or list of selectors
does not uniquely identify a record aka it is not sufficiently specific.

