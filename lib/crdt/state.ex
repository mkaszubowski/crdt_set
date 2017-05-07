defmodule Crdt.State do
  use GenServer

  alias Crdt.Set

  @name __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def add(user), do: GenServer.cast(@name, {:add, user})
  def remove(user), do: GenServer.cast(@name, {:remove, user})
  def get_users(), do: GenServer.call(@name, :get_users)

  def init([]) do
    Process.send_after(self(), :sync, 1000)
    {:ok, Set.new()}
  end

  def handle_cast({:add, user}, set) do
    new_set = Set.add(set, user)
    GenServer.abcast(Node.list(), @name, {:merge, new_set})
    {:noreply, new_set}
  end

  def handle_cast({:remove, user}, set) do
    new_set = Set.remove(set, user)
    GenServer.abcast(Node.list(), @name, {:merge, new_set})
    {:noreply, new_set}
  end

  def handle_cast({:merge, other_set}, set) do
    new_set = Set.merge(set, other_set)
    {:noreply, new_set}
  end

  def handle_call(:get_users, _from, set) do
    values = Set.values(set)
    {:reply, values, set}
  end

  def handle_info({:nodedown, node}, set) do
    new_set = Set.suspect(set, node)
    {:noreply, new_set}
  end

  def handle_info(:sync, set) do
    Enum.each(Node.list(), fn node -> Node.monitor(node, true) end)
    GenServer.abcast(Node.list(), @name, {:merge, set})
    Process.send_after(self(), :sync, 1000)

    {:noreply, set}
  end
end
