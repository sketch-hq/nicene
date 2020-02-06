defmodule Nicene.UnnecessaryPatternMatching do
  @moduledoc """
  Check to ensure that we aren't doing any unnecessary pattern matching or using unnecessary
  guard clauses for functions.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :design

  alias Nicene.Traverse

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    single_definitions =
      source_file
      |> Credo.Code.prewalk(&Traverse.get_funs/2)
      |> Enum.map(fn {_, name, arity, _} -> {name, arity} end)
      |> Enum.reduce(%{}, fn fun, acc -> Map.update(acc, fun, 1, &(&1 + 1)) end)
      |> Enum.filter(fn {{_, arity}, count} -> count == 1 and arity != 0 end)
      |> Enum.map(&elem(&1, 0))

    issue_fun = &issue_for(issue_meta, &1)

    check_fun = fn _, name, arity, _, args ->
      {name, arity} in single_definitions and pattern_matching?(args)
    end

    Credo.Code.prewalk(source_file, &Traverse.traverse(&1, &2, check_fun, issue_fun))
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
