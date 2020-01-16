defmodule Nicene.PublicFunctionsFirst do
  @moduledoc """
  Public functions in a module should be defined before private functions.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    case Credo.Code.prewalk(source_file, &get_funs/2) do
      [] ->
        []

      functions ->
        {_, last_public_function} =
          Enum.max_by(functions, fn
            {:def, line_no} -> line_no
            _ -> 0
          end)

        Enum.reduce(functions, [], &check_function(&1, &2, issue_meta, last_public_function))
    end
  end

  defp get_funs(
         {op, _, [{:when, _, [{_, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, [{op, line_no} | functions]}
  end

  defp get_funs({op, _, [{_, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, [{op, line_no} | functions]}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp check_function({:defp, line}, issues, issue_meta, public_line) when line < public_line do
    [issue_for(issue_meta, line) | issues]
  end

  defp check_function(_, issues, _, _), do: issues

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Private function is defined before a public function",
      line_no: line_no
    )
  end
end
