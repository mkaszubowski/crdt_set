defmodule Crdt.Set do
  @enforce_keys [:node]
  defstruct [:node, added: [], removed: [], suspected: []]

  defmodule Item do
    defstruct [:id, :value, :node]
  end

  alias Crdt.Set

  def new(), do: %Set{node: Node.self()}

  def add(set, value) do
    item = %Item{id: UUID.uuid4(), value: value, node: Node.self()}
    added = [item | set.added]

    %{set | added: added}
  end

  def remove(set, value) do
    ids =
      set.added
      |> Enum.filter(fn item -> item.value == value end)
      |> Enum.map(fn item -> item.id end)

    removed = Enum.uniq(set.removed ++ ids)

    %{set | removed: removed}
  end

  def values(set) do
    suspected_ids =
      Enum.map(set.suspected, fn tuple -> elem(tuple, 0) end)

    set.added
    |> Enum.reject(fn item -> item.id in set.removed end)
    |> Enum.reject(fn item -> item.id in suspected_ids end)
    |> Enum.map(fn item -> item.value end)
    |> Enum.uniq()
  end

  def merge(local, other) do
    added = Enum.uniq(local.added ++ other.added)
    removed = Enum.uniq(local.removed ++ other.removed)
    suspected = remove_suspected(local.suspected, other)

    %Set{local |
      added: added,
      removed: removed,
      suspected: suspected
    }
  end

  defp remove_suspected(suspected, other_set) do
    added_ids = Enum.map(other_set.added, fn item -> item.id end)

    Enum.reject(suspected, fn {id, node} ->
      node == other_set.node && id in added_ids
    end)
  end

  def suspect(set, failed_node) do
    new_suspected =
      set.added
      |> Enum.filter(fn item -> item.node == failed_node end)
      |> Enum.map(fn item -> {item.id, failed_node} end)

    suspected = Enum.uniq(set.suspected ++ new_suspected)

    %Set{set | suspected: suspected}
  end
end
