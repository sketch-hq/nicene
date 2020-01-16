defmodule Nicene.TrueFalseCaseStatements do
  @moduledoc """
  Do not use `case` when the only matches are `true` and `false`.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  @spec run(Credo.SourceFile.t(), list()) :: list(Credo.Issue.t())
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:case, [{:line, line_no} | _], [_, [do: clauses]]} = ast, issues, issue_meta) do
    {ast, check_clauses(clauses, issue_meta, line_no, issues)}
  end

  defp traverse(
         {:|>, _, [_, {:case, [{:line, line_no} | _], [[do: clauses]]}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, check_clauses(clauses, issue_meta, line_no, issues)}
  end

  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp check_clauses(
         [{:->, _, [[true], _]}, {:->, _, [[false], _]}],
         issue_meta,
         line_no,
         issues
       ) do
    [issue_for(issue_meta, line_no) | issues]
  end

  defp check_clauses(
         [
           {:->, _, [[true], _]},
           {:->, _, [[false], _]},
           {:->, _, [[{var, _, nil}], {var, _, nil}]}
         ],
         issue_meta,
         line_no,
         issues
       ) do
    [issue_for(issue_meta, line_no) | issues]
  end

  defp check_clauses(
         [
           {:->, _, [[true], _]},
           {:->, _, [[{_, _, nil}], _]},
         ],
         issue_meta,
         line_no,
         issues
       ) do
    [issue_for(issue_meta, line_no) | issues]
  end

  defp check_clauses(_, _, _, issues) do
    issues
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "`case` statement should be replaced with `if`.",
      line_no: line_no
    )
  end
end
