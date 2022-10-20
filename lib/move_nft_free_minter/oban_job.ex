defmodule MoveNFTFreeMinter.ObanJob do
  @moduledoc """
  Mainly for quick query and helpers
  """

  use Ecto.Schema

  # Copied from oban/job.ex
  schema "oban_jobs" do
    field :state, :string, default: "available"
    field :queue, :string, default: "default"
    field :worker, :string
    field :args, :map
    field :meta, :map, default: %{}
    field :tags, {:array, :string}, default: []
    field :errors, {:array, :map}, default: []
    field :attempt, :integer, default: 0
    field :attempted_by, {:array, :string}
    field :max_attempts, :integer, default: 20
    field :priority, :integer, default: 0

    field :attempted_at, :utc_datetime_usec
    field :cancelled_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :discarded_at, :utc_datetime_usec
    field :inserted_at, :utc_datetime_usec
    field :scheduled_at, :utc_datetime_usec
  end
end
