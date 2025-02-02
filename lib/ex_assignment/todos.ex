defmodule ExAssignment.Todos do
  @moduledoc """
  Provides operations for working with todos.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias ExAssignment.Repo

  alias ExAssignment.Todos.Todo
  alias ExAssignment.Cache

  @doc """
  Returns the list of todos, optionally filtered by the given type.

  ## Examples

      iex> list_todos(:open)
      [%Todo{}, ...]

      iex> list_todos(:done)
      [%Todo{}, ...]

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos(type) when type == true do
    Todo
    |> where(done: ^type)
    |> order_by([t], t.priority)
    |> Repo.all()
  end

  def list_todos(type) when type == false do
    Todo
    |> where(done: ^type)
    |> order_by([t], t.priority)
    |> Repo.all()
  end

  def list_todos() do
    Todo
    |> order_by([t], t.priority)
    |> Repo.all()
  end

  @doc """
  Returns the next todo that is recommended to be done by the system.

  ASSIGNMENT: ...
  """
  def get_recommended() do
    with todos <- list_todos(false),
         todos <- parse_todos_results(todos),
         {id, _value} <- List.first(todos) do
      recommended_todo = get_todo!(id)
      Cache.put(recommended_todo.id, recommended_todo)

      recommended_todo
    else
      nil ->
        []
    end
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Marks the todo referenced by the given id as checked (done).

  ## Examples

      iex> check(1)
      :ok

  """
  def check(id) do
    get_todo!(id)
    |> change(done: true)
    |> Repo.update()
    |> case do
      {:ok, todo} ->
        Cache.delete(todo.id)
        :ok
    end
  end

  @doc """
  Marks the todo referenced by the given id as unchecked (not done).

  ## Examples

      iex> uncheck(1)
      :ok

  """
  def uncheck(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: false]])
      |> Repo.update_all([])

    :ok
  end

  defp parse_todos_results(todos) when is_list(todos) do
    todos
    |> Enum.map(fn n -> {to_string(n.id), n.priority} end)
    |> Enum.uniq_by(fn {_, y} -> y end)
  end
end
