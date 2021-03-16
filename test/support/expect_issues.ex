defmodule Nicene.ExpectIssues do
  require Assertions

  import ExUnit.Assertions, only: [assert: 1]
  import Assertions, only: [assert_lists_equal: 3, assert_structs_equal: 3]

  def assert_expected_issues(source_file, checker, expected_count) do
    expected_issues =
      [source_file]
      |> Credo.Check.ConfigCommentFinder.run(nil, [])
      |> Enum.flat_map(fn {filename, comments} ->
        comments
        |> Enum.map(fn comment ->
          make_expected_issue_list(comment.instruction, filename, checker, comment)
        end)
        |> List.flatten()
      end)

    assert Enum.count(expected_issues) == expected_count

    source_file
    |> checker.run([])
    |> assert_issues(expected_issues)
  end

  defp make_expected_issue_list("expect-next-line", filename, checker, comment) do
    make_expected_issue_list("expect-next-lines:1", filename, checker, comment)
  end

  defp make_expected_issue_list("expect-next-lines:" <> line_count, filename, checker, comment) do
    1..String.to_integer(line_count)
    |> Enum.map(fn offset ->
      %Credo.Issue{
        filename: filename,
        category: checker.category,
        check: checker,
        line_no: comment.line_no + offset
      }
      |> add_params(comment.params)
    end)
  end

  defp add_params(issue, []) do
    issue
  end

  defp add_params(issue, [%Regex{} = pattern]) do
    %{issue | message: pattern}
  end

  def assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      if expected.message do
        assert Regex.match?(expected.message, issue.message)
      end
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no])
    end)
  end
end
