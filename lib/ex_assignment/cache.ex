defmodule ExAssignment.Cache do
  use GenServer

  @timer :timer.minutes(60)


  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:todos, [:set, :public, :named_table])
    scheduler()
    {:ok, %{}}
  end

  def delete(key) do
    GenServer.cast(__MODULE__, {:delete, key})
  end

  def put(key, data) do
    GenServer.cast(__MODULE__, {:put, key, data})
  end


   def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def handle_info(:clear_cache, state) do
    scheduler()
    {:noreply, state}
  end

  def handle_call({:get, key}, _, state) do
    t = :ets.lookup(:todos, key)

    {:reply, t, state}
  end

  def handle_cast({:delete, key}, state) do
    :ets.delete(:todos, key)
    {:noreply, state}
  end

  def handle_cast({:put, key, data}, state) do
    :ets.insert(:todos, {key, data})
    {:noreply, state}
  end


  defp scheduler do
    Process.send_after(self(), :clear_cache, @timer)
  end
end
