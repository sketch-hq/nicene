defmodule Nicene.PublicFunctionsFirst do
  @moduledoc """
  Public functions in a module should be defined before private functions.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability

  alias Nicene.Traverse

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Traverse.get_funs()
    |> Enum.group_by(
      fn {_type, module, _function, _arity, _line_no} -> module end,
      fn {type, _module, _function, _arity, line_no} -> {type, line_no} end
    )
    |> Map.values()
    |> Enum.reduce([], &check_funs(&1, &2, issue_meta))
  end

  defp check_funs(functions, acc, issue_meta) do
    case functions do
      [] ->
        acc

      functions ->
        functions
        |> Enum.max_by(fn
          {:def, line_no} -> line_no
          _ -> 0
        end)
        |> case do
          {:defp, _} ->
            []

          {_, last_public_function} ->
            Enum.reduce(
              functions,
              [],
              &check_function(&1, &2, issue_meta, last_public_function)
            )
        end
    end
  end

  defp check_function({:defp, line}, issues, issue_meta, public_line)
       when line < public_line do
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
