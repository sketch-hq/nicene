defmodule Nicene.AvoidImportsFromCurrentApplication do
  @moduledoc """
  Avoid importing functions from modules in the current OTP application, as this can really slow
  down incremental compile times. Importing frunctions from dependent applications are fine since
  those don't re-compile when making changes.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :refactoring, param_defaults: [namespaces: []]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    namespaces =
      params
      |> Params.get(:namespaces, __MODULE__)
      |> Enum.flat_map(&Module.split/1)

    source_file
    |> Credo.Code.prewalk(&check_imports(&1, &2, namespaces, issue_meta), {[], []})
    |> elem(0)
  end

  defp check_imports({:alias, _, [{:__aliases__, _, alias_parts}]} = ast, {issues, aliases}, _, _) do
    alias_parts = alias_parts |> Module.concat() |> Module.split()
    {ast, {issues, [alias_parts | aliases]}}
  end

  defp check_imports(
         {:import, meta, [{:__aliases__, _, module}]} = ast,
         {issues, aliases},
         namespaces,
         issue_meta
       ) do
    [namespace | _] = module |> Module.concat() |> Module.split()

    namespace =
      Enum.find_value(aliases, namespace, fn alias_parts ->
        if List.last(alias_parts) == namespace do
          hd(alias_parts)
        end
      end)

    if namespace in namespaces do
      {ast, {[issue_for(issue_meta, Keyword.get(meta, :line), namespace) | issues], aliases}}
    else
      {ast, {issues, aliases}}
    end
  end

  defp check_imports(ast, issues, _, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Import from configured namespaces found",
      line_no: line_no,
      trigger: trigger
    )
  end
end
