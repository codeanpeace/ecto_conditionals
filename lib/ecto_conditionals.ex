defmodule EctoConditionals do
  @moduledoc """
  Provides Ecto conditional helper functions for find_or_create-ing or upsert-ing records

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
  """

  # these macros decorate function calls by appending the repo as an addtional argument
  defmacro __using__([repo: repo]) do
    quote do
      import unquote(__MODULE__), only: [
        find_by: 2,
        find: 1,
        or_create: 1,
        find_or_create_by: 2,
        find_or_create: 1,
        update_or_insert: 1,
        upsert_by: 2,
        upsert: 1
      ]
      @repo unquote(repo)
    end
  end

  defmacro find_by(record_struct, selectors) do
    quote do
      unquote(__MODULE__).find_by(unquote(record_struct), unquote(selectors), @repo)
    end
  end

  defmacro find(record_struct) do
    quote do
      unquote(__MODULE__).find(unquote(record_struct), @repo)
    end
  end

  defmacro or_create({status, record_struct}) do
    quote do
      unquote(__MODULE__).or_create({unquote(status), unquote(record_struct)}, @repo)
    end
  end

  defmacro find_or_create_by(record_struct, selectors) do
    quote do
      unquote(__MODULE__).find_or_create_by(unquote(record_struct), unquote(selectors), @repo)
    end
  end

  defmacro find_or_create(record_struct) do
    quote do
      unquote(__MODULE__).find_or_create(unquote(record_struct), @repo)
    end
  end

  defmacro update_or_insert({status, record_struct}) do
    quote do
      unquote(__MODULE__).update_or_insert({unquote(status), unquote(record_struct)}, @repo)
    end
  end

  defmacro upsert_by(record_struct, selectors) do
    quote do
      unquote(__MODULE__).upsert_by(unquote(record_struct), unquote(selectors), @repo)
    end
  end

  defmacro upsert(record_struct) do
    quote do
      unquote(__MODULE__).upsert(unquote(record_struct), @repo)
    end
  end

  def find_by(%_{} = _record_struct, nil, _repo), do: {:error, "find_by requires a list of fields to select on"}
  def find_by(%_{} = _record_struct, [], _repo), do: {:error, "find_by requires a list of fields to select on"}
  def find_by(%_{} = record_struct, selectors, repo) when is_list(selectors) do
    with model = record_struct.__struct__,
         where = selectors
                 |> Enum.reject(&Kernel.is_nil/1)
                 |> Enum.map(fn s -> {s, record_struct |> Map.get(s)} end),
         found = model |> repo.get_by(where),
    do: if found, do: {:found, found}, else: {:not_found, record_struct}
  end
  def find_by(%_{} = record_struct, selector, repo), do: find_by(record_struct, [selector], repo)
  def find_by(_, _, _), do: {:error, "find_by/2 requires a resource struct and list of selectors arguments"}
  def find(%_{id: _id} = record_struct, repo), do: record_struct |> find_by(:id, repo)
  def find(%_{} = record_struct, repo), do: record_struct |> Map.merge(%{id: nil}) |> find_by(:id, repo)
  def find(_, _), do: {:error, "find/1 requires a struct with an id field in the first argument"}

  def or_create({:found, %_{} = found}, _repo), do: {:ok, found}
  def or_create({:not_found, %_{} = record_struct}, repo), do: repo.insert(record_struct)
  def or_create(error, _repo), do: error

  def find_or_create_by(record_struct, selectors, repo), do: record_struct |> find_by(selectors, repo) |> or_create(repo)
  def find_or_create(record_struct, repo), do: record_struct |> find(repo) |> or_create(repo)

  def upsert_by(%_{} = record_struct, selectors, repo) do
    model = record_struct.__struct__
    case record_struct |> find_by(selectors, repo) do
      {:found, found} -> found
      {:not_found, _} -> struct(model)
    end
    |> model.changeset(record_struct |> Map.from_struct)
    |> repo.insert_or_update
  end
  def upsert(%_{} = record_struct, repo), do: record_struct |> upsert_by(:id, repo)
end
