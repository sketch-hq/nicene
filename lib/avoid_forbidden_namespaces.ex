defmodule Nicene.AvoidForbiddenNamespaces do
  @moduledoc """
  Avoid calling forbidden namespaces. This is meant to be used for example
  to avoid calling `AppWeb` from `App` in Phoenix applications.
  It only works for top level namespaces.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :refactoring

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    from_namespace = params |> Keyword.get(:from) |> get_namespace()

    forbidden_namespaces =
      params
      |> Keyword.get(:forbid)
      |> Enum.map(fn module ->
        [_, namespace] = module |> Atom.to_string() |> String.split(".")

        namespace |> String.to_atom()
      end)

    source_file
    |> Credo.Code.prewalk(
      &check_usage(&1, &2, from_namespace, forbidden_namespaces, issue_meta),
      {[], nil}
    )
    |> elem(0)
  end

  defp check_usage({:defmodule, _, _} = ast, {issues, _current_namespace}, _, _, _) do
    current_namespace = ast |> Credo.Code.Module.name() |> get_namespace()

    {ast, {issues, current_namespace}}
  end

  defp check_usage(
         {:__aliases__, meta, [used_namespace | _]} = ast,
         {issues, current_namespace},
         from_namespace,
         forbidden_namespaces,
         issue_meta
       )
       when current_namespace == from_namespace do
    if used_namespace in forbidden_namespaces do
      {ast,
       {[issue_for(issue_meta, Keyword.get(meta, :line), used_namespace) | issues],
        current_namespace}}
    else
      {ast, {issues, current_namespace}}
    end
  end

  defp check_usage(ast, ctx, _, _, _) do
    {ast, ctx}
  end

  defp get_namespace(module_name) when is_atom(module_name) do
    [_ | [namespace | _]] =
      module_name
      |> Atom.to_string()
      |> String.split(".")

    namespace |> String.to_atom()
  end

  defp get_namespace(module_name) do
    module_name
    |> String.split(".")
    |> hd()
    |> String.to_atom()
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Usage of forbidden namespace found",
      line_no: line_no,
      trigger: trigger
    )
  end
end
