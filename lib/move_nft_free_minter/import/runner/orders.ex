defmodule MoveNFTFreeMinter.Import.Runner.Orders do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi

  alias MoveNFTFreeMinter.Import
  alias MoveNFTFreeMinter.Explorer.Model.Order

  @timeout 60_000

  def timeout, do: @timeout
  def option_key, do: :orders
  def ecto_schema_module, do: Order

  def run(multi, changes_list, %{timestamps: timestamps} = options) do
    insert_options =
      options
      |> Map.get(option_key(), %{})
      |> Map.take(~w(on_conflict timeout)a)
      |> Map.put_new(:timeout, @timeout)
      |> Map.put(:timestamps, timestamps)

    Multi.run(multi, :orders, fn repo, _ ->
      insert(repo, changes_list, insert_options)
    end)
  end

  def insert(repo, changes_list, %{timeout: timeout, timestamps: timestamps} = options)
      when is_list(changes_list) do
    on_conflict = Map.get_lazy(options, :on_conflict, &default_on_conflict/0)

    {:ok, _} =
      Import.insert_changes_list(
        repo,
        changes_list,
        conflict_target: :order_id,
        on_conflict: on_conflict,
        for: Order,
        returning: true,
        timeout: timeout,
        timestamps: timestamps
      )
  end

  def default_on_conflict do
    from(
      o in Order,
      update: [
        set: [
          status: fragment("EXCLUDED.status"),
          version: fragment("EXCLUDED.version"),
          taker: fragment("EXCLUDED.taker"),
          inserted_at: fragment("LEAST(?, EXCLUDED.inserted_at)", o.inserted_at),
          updated_at: fragment("GREATEST(?, EXCLUDED.updated_at)", o.updated_at)
        ]
      ],
      where: fragment("? < EXCLUDED.version", o.version) or fragment("EXCLUDED.version IS NULL")
    )
  end
end
