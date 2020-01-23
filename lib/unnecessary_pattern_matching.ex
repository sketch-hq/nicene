defmodule Nicene.UnnecessaryPatternMatching do
  @moduledoc """
  Check to ensure that we aren't doing any unnecessary pattern matching or using unnecessary
  guard clauses for functions.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :design

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    single_definitions =
      source_file
      |> Credo.Code.prewalk(&get_funs/2)
      |> Enum.reduce(%{}, fn fun, acc -> Map.update(acc, fun, 1, &(&1 + 1)) end)
      |> Enum.filter(fn {{_, arity}, count} -> count == 1 and arity != 0 end)
      |> Enum.map(&elem(&1, 0))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, single_definitions, issue_meta))
  end

  defp get_funs({op, _, [{:when, _, [{name, _, args} | _]} | _]} = ast, definitions)
       when op in [:def, :defp] do
    {ast, [{name, length(args)} | definitions]}
  end

  defp get_funs({op, _, [{name, _, args} | _]} = ast, definitions) when op in [:def, :defp] do
    {ast, [{name, length(args)} | definitions]}
  end

  defp get_funs(ast, definitions) do
    {ast, definitions}
  end

  defp traverse(
         {op, [{:line, line_no} | _], [{:when, _, [{name, _, args} | _]} | _]} = ast,
         issues,
         definitions,
         issue_meta
       )
       when op in [:def, :defp] do
    if {name, length(args)} in definitions do
      {ast, [issue_for(issue_meta, line_no) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(
         {op, [{:line, line_no} | _], [{name, _, args} | _]} = ast,
         issues,
         definitions,
         issue_meta
       )
       when op in [:def, :defp] do
    if {name, length(args)} in definitions and pattern_matching?(args) do
      {ast, [issue_for(issue_meta, line_no) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _, _) do
    {ast, issues}
  end

  defp pattern_matching?(ast) do
    Enum.any?(ast, fn
      {op, _, _} -> op == :=
      _ -> false
    end)
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Unnecessary pattern matching or guard clause detected",
      line_no: line_no
    )
  end
end
