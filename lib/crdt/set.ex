defmodule Crdt.Set do
  defstruct [added: [], removed: []]

  defmodule Item do
    defstruct [:id, :value, :node]
  end

  alias Crdt.Set

  def add(set, value) do
    item = %Item{id: UUID.uuid4()}
  end
end
