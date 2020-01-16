# credo:disable-for-this-file Nicene.TestsInTestFolder
defmodule Nicene.TestsInTestFolder do
  @moduledoc """
  Check to ensure all tests are in the correct folder.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :warning, exit_status: 1

  @doc false
  def run(source_file, params \\ []) do
    source = SourceFile.source(source_file)
    issue_meta = IssueMeta.for(source_file, params)

    if "lib" in Path.split(source_file.filename) do
      case Regex.run(~r/(\.Case[ \n,])|(\.[a-zA-Z]*Case[ \n,])|( assert )|( refute )/, source) do
        nil -> []
        _ -> [issue_for(issue_meta, source_file.filename)]
      end
    else
      []
    end
  end

  defp issue_for(issue_meta, filename) do
    format_issue(issue_meta,
      message: "Tests are in the `lib` folder",
      trigger: filename
    )
  end
end
