defmodule Nicene.TestsInTestFolderTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.TestsInTestFolder

  test "warns with a test in the lib folder" do
    expected_issues = [
      %Issue{
        category: :warning,
        check: TestsInTestFolder,
        filename: "lib/app/file_test.ex",
        line_no: nil,
        message: "Tests are in the `lib` folder"
      }
    ]

    """
    defmodule App.FileTest do
      use ExUnit.Case, async: true

      def test(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TestsInTestFolder.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(), do: assert :ok == :ok
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TestsInTestFolder.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(), do: refute :ok == :error
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TestsInTestFolder.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      use App.DataCase

      def test(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TestsInTestFolder.run([])
    |> assert_issues(expected_issues)
  end

  test "does not warn for correct ordering" do
    """
    defmodule App.FileTest do
      use ExUnit.Case

      def test(), do: :ok
    end
    """
    |> SourceFile.parse("test/app/file_test.ex")
    |> TestsInTestFolder.run([])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
