defmodule MoveNFTFreeMinter.Turbo do
  @moduledoc """
  Ecto Enhance API
  """

  import Ecto.Query, warn: false

  alias MoveNFTFreeMinter.Repo

  def get(queryable, id, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get(id)
    |> done(queryable, id)
  end

  def get(queryable, id) do
    queryable
    |> Repo.get(id)
    |> done(queryable, id)
  end

  @doc """
  simular to Repo.get_by/3, with standard result/error handle
  """
  def get_by(queryable, clauses, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        {:error, :not_found}

      result ->
        {:ok, result}
    end
  end

  def get_by(queryable, clauses) do
    queryable
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        {:error, :not_found}

      result ->
        {:ok, result}
    end
  end

  def create(schema, attrs) do
    schema
    |> struct
    |> schema.changeset(attrs)
    |> Repo.insert()
  end

  def update(content, attrs) do
    content
    |> content.__struct__.changeset(attrs)
    |> Repo.update()
  end

  def delete(content), do: Repo.delete(content)

  def findby_or_insert(queryable, clauses, attrs) do
    case queryable |> get_by(clauses) do
      {:ok, content} ->
        {:ok, content}

      {:error, _} ->
        queryable |> create(attrs)
    end
  end

  def done(nil), do: {:error, "record not found."}
  def done(result), do: {:ok, result}
  def done(result, _, _), do: {:ok, result}
  def done(nil, :boolean), do: {:ok, false}
  def done(_, :boolean), do: {:ok, true}
end
