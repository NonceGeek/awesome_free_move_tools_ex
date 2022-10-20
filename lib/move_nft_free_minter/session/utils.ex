defmodule MoveNFTFreeMinter.Session.Utils do
  @moduledoc false

  require Logger

  @type id :: binary()

  def random_node_aware_id() do
    node_part = node_hash(node())
    random_part = :crypto.strong_rand_bytes(9)
    binary = <<node_part::binary, random_part::binary>>
    # 16B + 9B = 25B is suitable for base32 encoding without padding
    Base.encode32(binary, case: :lower)
  end

  # Note: the result is always 16 bytes long
  defp node_hash(node) do
    content = Atom.to_string(node)
    :erlang.md5(content)
  end

  def node_from_node_aware_id(id) do
    binary = Base.decode32!(id, case: :lower)
    <<node_part::binary-size(16), _random_part::binary-size(9)>> = binary

    known_nodes = [node() | Node.list()]

    Enum.find_value(known_nodes, :error, fn node ->
      node_hash(node) == node_part && {:ok, node}
    end)
  end
end
