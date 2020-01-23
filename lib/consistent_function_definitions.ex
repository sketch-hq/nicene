defmodule Nicene.ConsistentFunctionDefinitions do
  @moduledoc """
  Function definitions should use one or the other style, not a mix of the two.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    funs = Credo.Code.prewalk(source_file, &get_funs/2, %{})

    source_file
    |> Credo.SourceFile.lines()
    |> Enum.reduce(%{}, &process_line(&1, &2, funs))
    |> Enum.map(fn {line_no, definitions} -> {line_no, Enum.reverse(definitions)} end)
    |> Enum.reduce([], &process_fun(&1, &2, issue_meta))
  end

  defp get_funs(
         {op, _, [{:when, _, [{name, [{:line, line_no} | _], _} | _]} | _]} = ast,
         functions
       )
       when op in [:def, :defp] do
    {ast, Map.put(functions, line_no, name)}
  end

  defp get_funs({op, _, [{name, [{:line, line_no} | _], _} | _]} = ast, functions)
       when op in [:def, :defp] do
    {ast, Map.put(functions, line_no, name)}
  end

  defp get_funs(ast, functions) do
    {ast, functions}
  end

  defp process_line({line_no, line}, acc, funs) when :erlang.is_map_key(line_no, funs) do
    def_type =
      if Regex.match?(~r/defp? #{funs[line_no]}.*\),(\z)|( do: .*)/, line) do
        :single_line
      else
        :multiline
      end

    Map.update(acc, funs[line_no], [{line_no, def_type}], &[{line_no, def_type} | &1])
  end

  defp process_line(_, acc, _) do
    acc
  end

  defp process_fun({_, [{_, def_type} | definitions]}, issues, issue_meta) do
    Enum.reduce(definitions, issues, fn
      {_, ^def_type}, acc -> acc
      {line_no, _}, acc -> [issue_for(issue_meta, line_no) | acc]
    end)
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Inconsistent function definition found",
      line_no: line_no
    )
  end
end
