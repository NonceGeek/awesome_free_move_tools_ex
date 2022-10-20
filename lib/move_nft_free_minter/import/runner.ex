defmodule MoveNFTFreeMinter.Import.Runner do
  @moduledoc false

  alias Ecto.Multi

  @typedoc """
  A callback module that implements this module's behaviour.
  """
  @type t :: module

  @typedoc """
  consensus changes extracted from a valid `Ecto.Changeset` produced by the `t:changeset_function_name/0` in
  `c:ecto_schemma_module/0`.
  """
  @type changes :: %{optional(atom) => term()}

  @typedoc """
  A list of `t:changes/0` to be imported by `c:run/3`.
  """
  @type changes_list :: [changes]

  @type changeset_function_name :: atom
  @type on_conflict :: :nothing | :replace_all | Ecto.Query.t()

  @typedoc """
  Runner-specific options under `c:option_key/0` in all options passed to `c:run/3`.
  """
  @type options :: %{
          required(:params) => [map()],
          optional(:on_conflict) => on_conflict(),
          optional(:timeout) => timeout,
          optional(:with) => changeset_function_name()
        }

  @doc """
  Key in `t:all_options` used by this `MoveNFTFreeMinter.Import` behaviour implementation.
  """
  @callback option_key() :: atom()

  @doc """
  The `Ecto.Schema` module that contains the `:changeset` function for validating `options[options_key][:params]`.
  """
  @callback ecto_schema_module() :: module()
  @callback run(Multi.t(), changes_list, %{optional(atom()) => term()}) :: Multi.t()
  @callback timeout() :: timeout()

  @doc """
  The optional list of runner-specific options.
  """
  @callback runner_specific_options() :: [atom()]

  @optional_callbacks runner_specific_options: 0
end
