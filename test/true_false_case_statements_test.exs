defmodule Nicene.TrueFalseCaseStatementsTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.TrueFalseCaseStatements

  test "warns if we're using case statements instead of if statements" do
    expected_issues = [
      %Issue{
        category: :readability,
        check: TrueFalseCaseStatements,
        filename: "lib/app/file_test.ex",
        line_no: 3,
        message: "`case` statement should be replaced with `if`."
      }
    ]

    """
    defmodule App.FileTest do
      def test(arg) do
        case valid?(arg) do
          true -> :ok
          false -> :error
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(arg) do
        case valid?(arg) do
          true -> :ok
          false -> :error
          response -> response
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(arg) do
        arg |> valid?() |> case do
          true -> :ok
          false -> :error
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(arg) do
        arg |> valid?() |> case do
          true -> :ok
          false -> :error
          response -> response
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(arg) do
        case valid?(arg) do
          true -> :ok
          _ -> :error
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      def test(arg) do
        case valid?(arg) do
          true -> :ok
          _error -> :error
        end
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues(expected_issues)
  end

  test "does not warn for correct case statement usage" do
    """
    defmodule App.FileTest do
      def test(arg) do
        case arg do
          nil -> :ok
          %{a: :b} -> arg
        end
      end
    end
    """
    |> SourceFile.parse("test/app/file_test.ex")
    |> TrueFalseCaseStatements.run([])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
