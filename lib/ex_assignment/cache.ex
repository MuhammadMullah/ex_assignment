defmodule ExAssignment.Cache do
  use GenServer

  @timer :timer.minutes(60)
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
    GenServer.cast(__MODULE__, {:delete, key})
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

  def handle_info(:clear_cache, state) do
    scheduler()
    {:noreply, state}
  end

  def handle_cast({:delete, key}, state) do
    :ets.delete(@table, key)
    {:noreply, state}
  end

  def handle_call({:put, key, data}, _, state) do
    result =
    with {:error, nil} <- get(key)  do
      insert_todo(key, data)
    else
      {:ok, data} ->
        insert_todo(key, data)
      error ->
        {:error, error}
    end

    {:reply, result, state}
  end


  defp scheduler do
    Process.send_after(self(), :clear_cache, @timer)
  end

  defp insert_todo(key, todo) do
    case :ets.insert(@table, {key, todo}) do
      true -> {:ok, {key, todo}}
      error -> {:error, error}
    end
  end
end
