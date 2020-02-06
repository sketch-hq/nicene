defmodule Nicene.FileAndModuleName do
  @moduledoc """
  Check to ensure that module names correspond to the file that it is defined it.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :warning

  @doc false
  def run(source_file, params \\ []) do
    lines = SourceFile.lines(source_file)
    issue_meta = IssueMeta.for(source_file, params)
    Enum.reduce(lines, [], &process_line(&1, &2, issue_meta, source_file))
  end

  defp process_line({line_no, line}, issues, issue_meta, source_file) do
    # credo:disable-for-next-line Nicene.FileAndModuleName
    case Regex.run(~r/\Adefmodule (.+) do/, line) do
      nil ->
        issues

      matches ->
        module_name = List.last(matches)
        prefix = source_file.filename |> Path.split() |> hd()
        suffix = Path.extname(source_file.filename)

        expected_file_name = prefix <> "/" <> Macro.underscore(module_name) <> suffix

        if expected_file_name == source_file.filename do
          issues
        else
          new_issue = issue_for(issue_meta, line_no, module_name, expected_file_name)

          [new_issue | issues]
        end
    end
  end

  defp issue_for(issue_meta, line_no, module_name, expected_file) do
    format_issue(issue_meta,
      message: "#{module_name} is not definied in the correct file - should be #{expected_file}",
      line_no: line_no,
      trigger: module_name
    )
  end
end
