defmodule Nicene.DocumentGraphqlSchema do
  @moduledoc """
  This checks that we're documenting our GraphQL schema thoroughly.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &check_schema_parts(&1, &2, issue_meta))
  end

  defs =
    Enum.map(
      [
        :field,
        :scalar,
        :arg,
        :object,
        :input_object,
        :directive,
        :interface,
        :union,
        :enum,
        :value
      ],
      fn fun ->
        quote do
          defp check_schema_parts(
                 {unquote(fun), meta, [_, [do: {:__block__, _, args}]]} = ast,
                 issues,
                 issue_meta
               ) do
            if List.keymember?(args, :description, 0) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts({unquote(fun), meta, [_, args]} = ast, issues, issue_meta)
               when is_list(args) do
            if Keyword.has_key?(args, :description) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts({unquote(fun), meta, [_, _]} = ast, issues, issue_meta) do
            {ast, [issue_for(issue_meta, meta[:line]) | issues]}
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, args, [do: {:__block__, _, body}]]} = ast,
                 issues,
                 issue_meta
               )
               when is_list(args) do
            if List.keymember?(body, :description, 0) or Keyword.has_key?(args, :description) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, _, args, [do: {:__block__, _, body}]]} = ast,
                 issues,
                 issue_meta
               )
               when is_list(args) do
            if List.keymember?(body, :description, 0) or Keyword.has_key?(args, :description) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, _, _, [do: {:__block__, _, body}]]} = ast,
                 issues,
                 issue_meta
               ) do
            if List.keymember?(body, :description, 0) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, args, [do: {:description, _, _}]]} = ast,
                 issues,
                 issue_meta
               ) do
            {ast, issues}
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, args, [do: {_, _, body}]]} = ast,
                 issues,
                 issue_meta
               )
               when is_list(args) do
            if List.keymember?(body, :description, 0) or Keyword.has_key?(args, :description) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts(
                 {unquote(fun), meta, [_, _, [do: {_, _, body}]]} = ast,
                 issues,
                 issue_meta
               ) do
            if List.keymember?(body, :description, 0) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end

          defp check_schema_parts({unquote(fun), meta, [_, _, args]} = ast, issues, issue_meta) do
            if Keyword.has_key?(args, :description) do
              {ast, issues}
            else
              {ast, [issue_for(issue_meta, meta[:line]) | issues]}
            end
          end
        end
      end
    )

  Module.eval_quoted(__MODULE__, defs)

  defp check_schema_parts(ast, issues, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message:
        "All fields and objects should be documented with the `description` macro or option.",
      line_no: line_no
    )
  end
end
