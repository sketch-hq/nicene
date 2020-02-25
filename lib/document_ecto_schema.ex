defmodule Nicene.DocumentEctoSchema do
  @moduledoc """
  Ecto schema associations should be documented
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :readability

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &get_schema_info(&1, &2), {[], nil, []})
    |> case do
      {_, _, []} ->
        []

      {_, description, relationships} ->
        relationships
        |> Enum.filter(&not_in_description?(&1, description))
        |> Enum.map(fn {_, message, line_no} ->
          format_issue(issue_meta, message: message, line_no: line_no)
        end)
    end
  end

  defp get_schema_info(
         {:typedoc, _, [description]} = ast,
         {descriptions, valid_description, fields}
       ) do
    {ast, {[description | descriptions], valid_description, fields}}
  end

  defp get_schema_info(
         {:type, _, [{:"::", _, [{:t, _, _} | _]}]} = ast,
         {descriptions, valid_description, fields}
       ) do
    case descriptions do
      [] ->
        {ast, {[], valid_description, fields}}

      [description | rest] ->
        {ast, {rest, description, fields}}
    end
  end

  defp get_schema_info(
         {:has_many, meta, [field, _]} = ast,
         {descriptions, valid_description, fields}
       ) do
    {ast, {descriptions, valid_description, [message_for(field, meta[:line]) | fields]}}
  end

  defp get_schema_info(ast, accumulator) do
    {ast, accumulator}
  end

  defp message_for(field_name, line_no) do
    {
      Atom.to_string(field_name),
      "Ecto association #{field_name} should be documented.",
      line_no
    }
  end

  def not_in_description?({field, _, _}, description) do
    is_nil(description) || not Regex.match?(~r/## Associations.*#{field} -.*/s, description)
  end
end
