defmodule MoveNFTFreeMinter.Import.Runner.Tokens do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi

  alias MoveNFTFreeMinter.Import
  alias MoveNFTFreeMinter.Explorer.Model.Token

  @timeout 60_000

  def timeout, do: @timeout
  def option_key, do: :tokens
  def ecto_schema_module, do: Token

  def run(multi, changes_list, %{timestamps: timestamps} = options) do
    insert_options =
      options
      |> Map.get(option_key(), %{})
      |> Map.take(~w(on_conflict timeout)a)
      |> Map.put_new(:timeout, @timeout)
      |> Map.put(:timestamps, timestamps)

    Multi.run(multi, :tokens, fn repo, _ ->
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
        conflict_target: :token_id,
        # on_conflict: on_conflict,
        on_conflict: :nothing,
        for: Token,
        returning: true,
        timeout: timeout,
        timestamps: timestamps
      )
  end

  def default_on_conflict do
    from(
      token in Token,
      update: [
        set: [
          supply: fragment("EXCLUDED.supply"),
          inserted_at: fragment("LEAST(?, EXCLUDED.inserted_at)", token.inserted_at),
          updated_at: fragment("GREATEST(?, EXCLUDED.updated_at)", token.updated_at)
        ]
      ],
      where:
        fragment(
          "(EXCLUDED.supply) IS DISTINCT FROM (?)",
          token.supply
        )
    )
  end
end
