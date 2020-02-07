defmodule Nicene.NoSpecsPrivateFunctions do
  @moduledoc """
  Private functions should not have typespecs
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :design

  alias Nicene.Traverse

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    specs = Credo.Code.prewalk(source_file, &Traverse.find_specs/2)

    issue_fun = &issue_for(issue_meta, &1, &2)
    check_fun = fn _, name, arity, _, _ -> {name, arity} in specs end
    Credo.Code.prewalk(source_file, &Traverse.traverse_private(&1, &2, check_fun, issue_fun))
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Private functions should not have @spec annotations",
      trigger: trigger,
      line_no: line_no
    )
  end
end
