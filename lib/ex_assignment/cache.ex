defmodule ExAssignment.Cache do
  @moduledoc """
    This module handles caching of the todos to our ets in-memory cache table. It also runs
    scheduler to clear the cache after every 1 hour.
  """
  use GenServer

  @timer :timer.minutes(30)
  @table :todos

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [:set, :public, :named_table])
    scheduler()
    {:ok, %{}}
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def put(key, data) do
    GenServer.call(__MODULE__, {:put, key, data})
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{_key, todo}] -> {:ok, todo}
      [] -> {:error, nil}
    end
  end

  def handle_info({:clear_cache, key}, state) do
    clear_cache(key)
    {:noreply, state}
  end

  def handle_call({:put, key, data}, _, state) do
    result =
      with {:error, nil} <- get(key) do
        insert_todo(key, data)
      else
        {:ok, data} ->
          insert_todo(key, data)

        error ->
          {:error, error}
      end

    {:reply, result, state}
  end

  @doc false
  @spec handle_call({:delete, {String.t(), String.t()}}, pid, map()) ::
          {:ok, tuple()} | {:error, term()}
  def handle_call({:delete, key}, _from, state) do
    result = :ets.delete(@table, key)

    {:reply, result, state}
  end

  @doc false
  defp scheduler(key \\ nil) do
    Process.send_after(self(), {:clear_cache, key}, @timer)
  end

  @doc false
  @spec insert_todo(String.t(), map()) :: {:ok, tuple()} | {:error, term()}
  defp insert_todo(key, todo) do
    case :ets.insert(@table, {key, todo}) do
      true -> {:ok, {key, todo}}
      error -> {:error, error}
    end
  end

  defp clear_cache(key) do
    case delete(key) do
      true ->
        :ok
    end
  end
end
