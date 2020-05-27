defmodule Nicene.EnsureTestFilePattern do
  @moduledoc """
  Test files should match the configured test file pattern so they're not skipped when running
  tests.
  """
  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high, category: :warning

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    filename = source_file.filename
    test_pattern = Keyword.get(Mix.Project.config(), :test_pattern, "*_test.exs")

    {:ok, test_regex} =
      test_pattern
      |> String.replace("**", "*")
      |> String.replace("*", ".*")
      |> Regex.compile()

    if Regex.match?(~r"^test/.*\.exs", filename) and not Regex.match?(test_regex, filename) do
      [issue_for(issue_meta, filename, test_pattern)]
    else
      []
    end
  end

  defp issue_for(issue_meta, filename, test_pattern) do
    format_issue(issue_meta,
      message: "test file #{filename} does not match the test pattern #{test_pattern}"
    )
  end
end
