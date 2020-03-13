defmodule Nicene.Traverse do
  @moduledoc false
  # Functions to help us traverse ASTs for common patterns

  @doc false
  @spec get_funs(Macro.t(), list()) :: {Macro.t(), list()}
  def get_funs({op, _, [{:when, meta, [{name, _, args} | _]} | _]} = ast, definitions)
      when op in [:def, :defp] do
    line_no = Keyword.get(meta, :line)
    {ast, [{op, name, arity(args), line_no} | definitions]}
  end

  def get_funs({op, _, [{name, meta, args} | _]} = ast, definitions) when op in [:def, :defp] do
    line_no = Keyword.get(meta, :line)
    {ast, [{op, name, arity(args), line_no} | definitions]}
  end

  def get_funs({:quote, meta, _}, definitions) do
    {{:quote, meta, []}, definitions}
  end

  def get_funs(ast, definitions) do
    {ast, definitions}
  end

  @doc false
  @spec traverse(Macro.t(), list(), fun(), fun()) :: {Macro.t(), list()}
  def traverse(
        {op, [{:line, line_no} | _], [{:when, _, [{name, _, args} | _]} | _]} = ast,
        issues,
        check_fun,
        issue_fun
      )
      when op in [:def, :defp] do
    if check_fun.(op, name, arity(args), line_no, args) do
      {ast, [issue_fun.(line_no, name) | issues]}
    else
      {ast, issues}
    end
  end

  def traverse(
        {op, [{:line, line_no} | _], [{name, _, args} | _]} = ast,
        issues,
        check_fun,
        issue_fun
      )
      when op in [:def, :defp] do
    if check_fun.(op, name, arity(args), line_no, args) do
      {ast, [issue_fun.(line_no, name) | issues]}
    else
      {ast, issues}
    end
  end

  def traverse(ast, issues, _, _) do
    {ast, issues}
  end

  @doc false
  @spec traverse_private(Macro.t(), list(), fun(), fun()) :: {Macro.t(), list()}
  def traverse_private(
        {:defp, meta, [{:when, _, def_ast} | _]},
        issues,
        check_fun,
        issue_fun
      ) do
    traverse({:defp, meta, def_ast}, issues, check_fun, issue_fun)
  end

  def traverse_private(
        {:defp = op, meta, [{name, _, args} | _]} = ast,
        issues,
        check_fun,
        issue_fun
      ) do
    line_no = Keyword.get(meta, :line)

    if check_fun.(op, name, arity(args), line_no, args) do
      {ast, [issue_fun.(line_no, name) | issues]}
    else
      {ast, issues}
    end
  end

  def traverse_private(ast, issues, _specs, _issue_meta) do
    {ast, issues}
  end

  @doc false
  @spec find_specs(Macro.t(), list()) :: {Macro.t(), list()}
  def find_specs(
        {:spec, _, [{:when, _, [{:"::", _, [{name, _, args}, _]}, _]} | _]} = ast,
        specs
      ) do
    {ast, [{name, arity(args)} | specs]}
  end

  def find_specs({:spec, _, [{_, _, [{name, _, args} | _]}]} = ast, specs) do
    {ast, [{name, arity(args)} | specs]}
  end

  def find_specs({:impl, _, [impl]} = ast, specs) when impl != false do
    {ast, [:impl | specs]}
  end

  def find_specs({:defp, meta, [{:when, _, def_ast} | _]}, [:impl | specs]) do
    find_specs({:def, meta, def_ast}, [:impl | specs])
  end

  def find_specs({:defp, meta, def_ast}, [:impl | specs]) do
    find_specs({:def, meta, def_ast}, [:impl | specs])
  end

  def find_specs(ast, issues) do
    {ast, issues}
  end

  defp arity(nil), do: 0
  defp arity(args), do: length(args)
end
