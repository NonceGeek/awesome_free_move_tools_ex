defmodule MoveNFTFreeMinter.Import do
  @moduledoc """
  Bulk importing of data into `MoveNFTFreeMinter.Repo`
  """

  alias Ecto.Changeset

  alias MoveNFTFreeMinter.Repo
  alias MoveNFTFreeMinter.Import

  @stages [
    Import.Stage.Explorer
  ]

  @runners Enum.flat_map(@stages, fn stage -> stage.runners() end)
  @transaction_timeout :timer.minutes(4)
  @global_options ~w(broadcast timeout)a
  @local_options ~w(on_conflict params with timeout)a

  @doc """
  import Ecto.Multi

  ## Examples

    iex> data = %{
    ...> tokens: %{params: []},
    ...> events: %{params: []},
    ...> orders: %{params: []},
    }

    iex> MoveNFTFreeMinter.Explorer.Import.all(data)

  """
  def run(options) when is_map(options) do
    with {:ok, runner_options_pairs} <- validate_options(options),
         {:ok, valid_runner_option_pairs} <- validate_runner_options_pairs(runner_options_pairs),
         {:ok, runner_to_changes_list} <- runner_to_changes_list(valid_runner_option_pairs),
         {:ok, data} <- insert_runner_to_changes_list(runner_to_changes_list, options) do
      {:ok, data}
    end
  end

  defp runner_to_changes_list(runner_options_pairs) when is_list(runner_options_pairs) do
    runner_options_pairs
    |> Stream.map(fn {runner, options} -> runner_changes_list(runner, options) end)
    |> Enum.reduce({:ok, %{}}, fn
      {:ok, {runner, changes_list}}, {:ok, acc_runner_to_changes_list} ->
        {:ok, Map.put(acc_runner_to_changes_list, runner, changes_list)}

      {:ok, _}, {:error, _} = error ->
        error

      {:error, _} = error, {:ok, _} ->
        error

      {:error, runner_changesets}, {:error, acc_changesets} ->
        {:error, acc_changesets ++ runner_changesets}
    end)
  end

  defp runner_changes_list(runner, %{params: params} = options) do
    ecto_schema_module = runner.ecto_schema_module()
    changeset_function_name = Map.get(options, :with, :changeset)
    struct = ecto_schema_module.__struct__()

    params
    |> Stream.map(&apply(ecto_schema_module, changeset_function_name, [struct, &1]))
    |> Enum.reduce({:ok, []}, fn
      changeset = %Changeset{valid?: false}, {:ok, _} ->
        {:error, [changeset]}

      changeset = %Changeset{valid?: false}, {:error, acc_changesets} ->
        {:error, [changeset | acc_changesets]}

      %Changeset{changes: changes, valid?: true}, {:ok, acc_changes} ->
        {:ok, [changes | acc_changes]}

      %Changeset{valid?: true}, {:error, _} = error ->
        error

      :ignore, error ->
        {:error, error}
    end)
    |> case do
      {:ok, changes} -> {:ok, {runner, changes}}
      {:error, _} = error -> error
    end
  end

  defp validate_options(options) when is_map(options) do
    local_options = Map.drop(options, @global_options)

    {reverse_runner_options_pairs, unknown_options} =
      Enum.reduce(@runners, {[], local_options}, fn runner, {acc_runner_options_pairs, unknown_options} = acc ->
        option_key = runner.option_key()

        case local_options do
          %{^option_key => option_value} ->
            {[{runner, option_value} | acc_runner_options_pairs], Map.delete(unknown_options, option_key)}

          _ ->
            acc
        end
      end)

    # {:ok, Enum.reverse(reverse_runner_options_pairs)}
    case Enum.empty?(unknown_options) do
      true -> {:ok, Enum.reverse(reverse_runner_options_pairs)}
      false -> {:error, {:unknown_options, unknown_options}}
    end
  end

  defp validate_runner_options_pairs(runner_options_pairs) when is_list(runner_options_pairs) do
    {status, reversed} =
      runner_options_pairs
      |> Stream.map(fn {runner, options} -> validate_runner_options(runner, options) end)
      |> Enum.reduce({:ok, []}, fn
        :ignore, acc ->
          acc

        {:ok, valid_runner_option_pair}, {:ok, valid_runner_options_pairs} ->
          {:ok, [valid_runner_option_pair | valid_runner_options_pairs]}

        {:ok, _}, {:error, _} = error ->
          error

        {:error, reason}, {:ok, _} ->
          {:error, [reason]}

        {:error, reason}, {:error, reasons} ->
          {:error, [reason | reasons]}
      end)

    {status, Enum.reverse(reversed)}
  end

  defp validate_runner_options(runner, options) when is_map(options) do
    option_key = runner.option_key()

    runner_specific_options =
      if Map.has_key?(Enum.into(runner.__info__(:functions), %{}), :runner_specific_options) do
        runner.runner_specific_options()
      else
        []
      end

    case {validate_runner_option_params_required(option_key, options), validate_runner_options_known(option_key, options, runner_specific_options)} do
      {:ignore, :ok} -> :ignore
      {:ignore, {:error, _} = error} -> error
      {:ok, :ok} -> {:ok, {runner, options}}
      {:ok, {:error, _} = error} -> error
      {{:error, reason}, :ok} -> {:error, [reason]}
      {{:error, reason}, {:error, reasons}} -> {:error, [reason | reasons]}
    end
  end

  defp validate_runner_option_params_required(_, %{params: params}) do
    case Enum.empty?(params) do
      false -> :ok
      true -> :ignore
    end
  end

  # defp validate_runner_option_params_required(runner_option_key, _),
  #   do: {:error, {:required, [runner_option_key, :params]}}

  # @local_options ~w(on_conflict params with timeout)a

  defp validate_runner_options_known(runner_option_key, options, runner_specific_options) do
    base_unknown_option_keys = Map.keys(options) -- @local_options
    unknown_option_keys = base_unknown_option_keys -- runner_specific_options

    if Enum.empty?(unknown_option_keys) do
      :ok
    else
      reasons = Enum.map(unknown_option_keys, &{:unknown, [runner_option_key, &1]})

      {:error, reasons}
    end
  end

  defp runner_to_changes_list_to_multis(runner_to_changes_list, options)
       when is_map(runner_to_changes_list) and is_map(options) do
    timestamps = timestamps()
    full_options = Map.put(options, :timestamps, timestamps)

    {multis, final_runner_to_changes_list} =
      Enum.flat_map_reduce(@stages, runner_to_changes_list, fn stage, remaining_runner_to_changes_list ->
        stage.multis(remaining_runner_to_changes_list, full_options)
      end)

    unless Enum.empty?(final_runner_to_changes_list) do
      raise ArgumentError,
            "No stages consumed the following runners: #{final_runner_to_changes_list |> Map.keys() |> inspect()}"
    end

    multis
  end

  def insert_changes_list(repo, changes_list, options)
      when is_atom(repo) and is_list(changes_list) do
    ecto_schema_module = Keyword.fetch!(options, :for)

    timestamped_changes_list = timestamp_changes_list(changes_list, Keyword.fetch!(options, :timestamps))

    {_, inserted} =
      repo.safe_insert_all(
        ecto_schema_module,
        timestamped_changes_list,
        Keyword.delete(options, :for)
      )

    {:ok, inserted}
  end

  defp timestamp_changes_list(changes_list, timestamps) when is_list(changes_list) do
    Enum.map(changes_list, &timestamp_params(&1, timestamps))
  end

  defp timestamp_params(changes, timestamps) when is_map(changes) do
    Map.merge(changes, timestamps)
  end

  defp insert_runner_to_changes_list(runner_to_changes_list, options)
       when is_map(runner_to_changes_list) do
    runner_to_changes_list
    |> runner_to_changes_list_to_multis(options)
    |> logged_import(options)
  end

  defp logged_import(multis, options) when is_list(multis) and is_map(options),
    do: import_transactions(multis, options)

  defp import_transactions(multis, options) when is_list(multis) and is_map(options) do
    Enum.reduce_while(multis, {:ok, %{}}, fn multi, {:ok, acc_changes} ->
      case import_transaction(multi, options) do
        {:ok, changes} -> {:cont, {:ok, Map.merge(acc_changes, changes)}}
        {:error, _, _, _} = error -> {:halt, error}
      end
    end)
  rescue
    exception in DBConnection.ConnectionError ->
      case Exception.message(exception) do
        "tcp recv: closed" <> _ -> {:error, :timeout}
        _ -> reraise exception, __STACKTRACE__
      end
  end

  defp import_transaction(multi, options) when is_map(options) do
    Repo.logged_transaction(multi, timeout: Map.get(options, :timeout, @transaction_timeout))
  end

  def timestamps do
    now = DateTime.utc_now()
    %{inserted_at: now, updated_at: now}
  end
end
