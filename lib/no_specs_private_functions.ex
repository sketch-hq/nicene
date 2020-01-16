defmodule Nicene.NoSpecsPrivateFunctions do
  @moduledoc """
  Private functions should not have typespecs
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :design, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    specs = Credo.Code.prewalk(source_file, &find_specs(&1, &2))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, specs, issue_meta))
  end

  defp find_specs(
         {:spec, _, [{:when, _, [{:"::", _, [{name, _, args}, _]}, _]} | _]} = ast,
         specs
       ) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:spec, _, [{_, _, [{name, _, args} | _]}]} = ast, specs)
       when is_list(args) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:impl, _, [impl]} = ast, specs) when impl != false do
    {ast, [:impl | specs]}
  end

  defp find_specs({:defp, meta, [{:when, _, def_ast} | _]}, [:impl | specs]) do
    find_specs({:def, meta, def_ast}, [:impl | specs])
  end

  defp find_specs({:defp, _, [{name, _, nil}, _]} = ast, [:impl | specs]) do
    {ast, [{name, 0} | specs]}
  end

  defp find_specs({:defp, _, [{name, _, args}, _]} = ast, [:impl | specs]) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs(ast, issues) do
    {ast, issues}
  end

  defp traverse(
         {:defp, meta, [{:when, _, def_ast} | _]},
         issues,
         specs,
         issue_meta
       ) do
    traverse({:defp, meta, def_ast}, issues, specs, issue_meta)
  end

  defp traverse(
         {:defp, meta, [{name, _, args} | _]} = ast,
         issues,
         specs,
         issue_meta
       )
       when is_list(args) do
    if {name, length(args)} in specs do
      {ast, [issue_for(issue_meta, meta[:line], name) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _specs, _issue_meta) do
    {ast, issues}
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
