defmodule Nicene.FileTopToBottom do
  @moduledoc """
  Invokations of functions should be before definitions of those functions.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    functions =
      source_file
      |> Credo.Code.prewalk(&get_funs/2)
      |> Enum.reduce(%{}, fn {fun, line}, acc ->
        Map.update(acc, fun, line, &max(&1, line))
      end)

    source_file
    |> SourceFile.lines()
    |> Enum.reduce([], &process_line(&1, &2, issue_meta, functions))
  end

  defp get_funs(
         {op, _, [{:when, _, [{name, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, [{name, line_no} | functions]}
  end

  defp get_funs({op, _, [{name, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, [{name, line_no} | functions]}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp process_line({line_no, line}, issues, issue_meta, functions) do
    if Enum.any?(functions, &function_in_line?(&1, line, line_no)) do
      [issue_for(issue_meta, line_no) | issues]
    else
      issues
    end
  end

  defp function_in_line?({function, definiton_line_no}, line, line_no)
       when definiton_line_no < line_no do
    line =~ "\s#{function}("
  end

  defp function_in_line?(_, _, _) do
    false
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Function is defined before it's called",
      line_no: line_no
    )
  end
end
