defmodule MoveNFTFreeMinter.Import.Stage.Explorer do
  @moduledoc false

  alias MoveNFTFreeMinter.Import.{Runner, Stage}

  @behaviour Stage

  @impl Stage
  def runners,
    do: [
      Runner.Events,
      Runner.Tokens,
      Runner.Orders
    ]

  @impl Stage
  def multis(runner_to_changes_list, options) do
    {final_multi, final_remaining_runner_to_changes_list} = Stage.single_multi(runners(), runner_to_changes_list, options)

    {[final_multi], final_remaining_runner_to_changes_list}
  end
end
