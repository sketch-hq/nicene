defmodule Nicene.EnsureTestFilePatternTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.EnsureTestFilePattern

  test "finds issues" do
    """
    defmodule App.FileTest do
      use ExUnit.Case

      test "ok" do
        assert true
      end
    end
    """
    |> SourceFile.parse("test/app/file.exs")
    |> EnsureTestFilePattern.run()
    |> assert_issues([
      %Issue{
        category: :warning,
        check: EnsureTestFilePattern,
        filename: "test/app/file.exs",
        message: "test file test/app/file.exs does not match the test pattern *_test.exs"
      }
    ])
  end

  test "does not find an issue if the file matches the test pattern" do
    """
    defmodule App.FileTest do
      use ExUnit.Case

      test "ok" do
        assert true
      end
    end
    """
    |> SourceFile.parse("test/app/file_test.exs")
    |> EnsureTestFilePattern.run()
    |> assert_issues([])
  end

  test "does not find an issue if the file isn't in the `test` directory" do
    """
    defmodule App.File do
      use ExUnit.Case

      test "ok" do
        assert true
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> EnsureTestFilePattern.run()
    |> assert_issues([])
  end

  test "does not find an issue if the file isn't an `.exs` file" do
    """
    defmodule App.File do
      use ExUnit.Case

      test "ok" do
        assert true
      end
    end
    """
    |> SourceFile.parse("test/app/file.ex")
    |> EnsureTestFilePattern.run()
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
