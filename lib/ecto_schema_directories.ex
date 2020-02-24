defmodule Nicene.EctoSchemaDirectories do
  @moduledoc """
  Ecto schemas should not be in directories with other types of files.
  """
  @explanation [check: @moduledoc]

  require Logger

  use Credo.Check, base_priority: :high, category: :refactoring

  @doc false
  def run(source_file, params \\ []) do
    run(source_file, params, other_files(source_file.filename))
  end

  def run(source_file, params, other_files) do
    issue_meta = IssueMeta.for(source_file, params)
    is_schema = Credo.Code.prewalk(source_file, &schema?/2, false)

    if is_schema and not Enum.all?(other_files, &schema?/1) do
      [issue_for(issue_meta, source_file.filename)]
    else
      []
    end
  end

  defp other_files(filename) do
    "#{Path.dirname(filename)}/*.ex"
    |> Path.wildcard()
    |> read_files()
  end

  defp read_files(files) do
    Enum.reduce(files, [], fn file, acc ->
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

  defp schema?(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, filename) do
    format_issue(issue_meta,
      message: "#{filename} is in a directory with files that are not Ecto schemas"
    )
  end
end
