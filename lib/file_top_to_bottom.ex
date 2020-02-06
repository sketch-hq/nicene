defmodule Nicene.FileTopToBottom do
  @moduledoc """
  Invokations of functions should be before definitions of those functions.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    functions = Credo.Code.prewalk(source_file, &get_funs/2, %{})
    Credo.Code.prewalk(source_file, &process_lines(&1, &2, functions, issue_meta))
  end

  defp get_funs(
         {op, _, [{:when, _, [{name, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, Map.update(functions, name, line_no, &max(&1, line_no))}
  end

  defp get_funs({op, _, [{name, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, Map.update(functions, name, line_no, &max(&1, line_no))}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp process_lines(
         {op, _, [{:when, _, [{name, _, _} | _] = definitions} | _]} = ast,
         issues,
         functions,
         issue_meta
       )
       when op in [:def, :defp] do
    functions = Map.delete(functions, name)

    issues =
      Enum.reduce(
        definitions,
        issues,
        &check_function_definition(&1, &2, functions, issue_meta)
      )

    {ast, issues}
  end

  defp process_lines(
         {op, _, [{name, _, _} | _] = definitions} = ast,
         issues,
         functions,
         issue_meta
       )
       when op in [:def, :defp] do
    functions = Map.delete(functions, name)

    issues =
      Enum.reduce(
        definitions,
        issues,
        &check_function_definition(&1, &2, functions, issue_meta)
      )

    {ast, issues}
  end

  defp process_lines(ast, issues, _, _) do
    {ast, issues}
  end

  defp check_function_definition(body, issues, functions, issue_meta) do
    body
    |> function_in_body([], functions)
    |> List.flatten()
    |> case do
      [] -> issues
      line_numbers -> Enum.reduce(line_numbers, issues, &[issue_for(issue_meta, &1) | &2])
    end
  end

  defp function_in_body({_, _, nil}, line_nos, _) do
    line_nos
  end

  defp function_in_body({name, [{:line, line} | _], body}, line_nos, functions) do
    line_nos =
      Enum.reduce(functions, line_nos, fn
        {^name, line_no}, acc when line_no < line -> [line_no | acc]
        _, acc -> acc
      end)

    Enum.reduce(body, line_nos, &function_in_body(&1, &2, functions))
  end

  defp function_in_body({:__block__, _, definitions}, line_nos, functions) do
    Enum.reduce(definitions, line_nos, &function_in_body(&1, &2, functions))
  end

  defp function_in_body([do: definition], line_nos, functions) do
    function_in_body(definition, line_nos, functions)
  end

  defp function_in_body(_, line_nos, _) do
    line_nos
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Function is defined before it's called",
      line_no: line_no
    )
  end
end
