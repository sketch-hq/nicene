defmodule Nicene.EctoSchemaDirectories do
  @moduledoc """
  Ecto schemas should not be in directories with other types of files.
  """
  @explanation [check: @moduledoc]

  require Logger

  use Credo.Check, base_priority: :high, category: :refactoring

  @doc false
  def run(source_file, params \\ []) do
    is_schema? = Credo.Code.prewalk(source_file, &schema?/2, false)

    if is_schema? do
      sibling_contents = get_sibling_file_contents(source_file.filename)
      ensure_all_siblings_are_schema(source_file, sibling_contents, params)
    else
      []
    end
  end

  # exported for testing purposes only
  @doc false
  def ensure_all_siblings_are_schema(source_file, sibling_contents, params) do
    if Enum.all?(sibling_contents, &schema?/1) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      [issue_for(issue_meta, source_file.filename)]
    end
  end

  defp get_sibling_file_contents(filename) do
    "#{Path.dirname(filename)}/*.ex"
    |> Path.wildcard()
    |> Enum.reduce([], fn file, acc ->
      case File.read(file) do
        {:ok, binary} ->
          [binary | acc]

        {:error, error} ->
          Logger.warn("Unable to read file #{file} - #{inspect(error)}")
          acc
      end
    end)
  end

  defp schema?(code) do
    code
    |> Code.string_to_quoted()
    |> Credo.Code.prewalk(&schema?/2, false)
  end

  defp schema?({:schema, _, [schema, _]} = ast, _) when is_binary(schema) do
    {ast, true}
  end

  defp schema?({:embedded_schema, _, _} = ast, _) do
    {ast, true}
  end

  defp schema?(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, filename) do
    format_issue(issue_meta,
      message: "#{filename} is in a directory with files that are not Ecto schemas"
    )
  end
end
