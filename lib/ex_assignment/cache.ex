defmodule ExAssignment.Cache do
  use GenServer

  @timer :timer.minutes(1)


  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    scheduler()
    {:ok, %{}}
  end

  def handle_info(:clear_cache, state) do
    IO.puts("CACHE CLEARED")
    IO.puts("CACHE CLEARED")
    IO.puts("CACHE CLEARED")
    IO.puts("*************")

    scheduler()
    {:noreply, state}
  end


  defp scheduler do
    Process.send_after(self(), :clear_cache, @timer)
  end
end
