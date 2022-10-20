defmodule MoveNFTFreeMinterWeb.Helpers do
  @moduledoc false

  @doc """
  Short Address
  """
  def display_address(address_hash) do
    <<head::binary-size(6), _::binary-size(56), rest::binary-size(4)>> = to_string(address_hash)
    head <> "..." <> rest
  end
end
