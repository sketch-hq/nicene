defmodule Nicene.ConsistentFunctionDefinitionsTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.ConsistentFunctionDefinitions

  test "finds issues" do
    """
    defmodule App.File do
      def test(%{}), do: :ok

      def test(_) do
        :err
      end

      def test(other) do
        :other
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 4,
        message: "Inconsistent function definition found"
      },
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 8,
        message: "Inconsistent function definition found"
      }
    ])

    """
    defmodule App.File do
      def test(arg) when is_map(arg), do: :ok

      def test(_) do
        :err
      end

      def test(other) do
        :other
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 4,
        message: "Inconsistent function definition found"
      },
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 8,
        message: "Inconsistent function definition found"
      }
    ])
  end

  test "doesn't have false positives" do
    """
    defmodule App.File do
      def test(%{}), do: :ok

      def test(_), do: :err

      def other_test(%{}) do
        :ok
      end

      def other_test(_) do
        :err
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([])

    """
    defmodule App.File do
      def test(arg) when is_map(arg), do: :ok

      def test(_), do: :err

      def other_test(%{}) do
        :ok
      end

      def other_test(_) do
        :err
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([])

    ~S"""
    defmodule App.File do
      def test(params \\ %{})
      def test(%{}), do: :ok

      def test(_), do: :err

      def other_test(%{}) do
        :ok
      end

      def other_test(_) do
        :err
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
