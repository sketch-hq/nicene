defmodule Nicene.FileTopToBottomTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.FileTopToBottom

  test "warns with files that don't read top to bottom" do
    """
    defmodule App.File do
      def test_2(), do: test_3()

      def test() do
        IO.inspect("IN HERE")
        test_2()
      end

      def test_3(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([
      %Issue{
        category: :readability,
        check: FileTopToBottom,
        filename: "lib/app/file.ex",
        line_no: 2,
        message: "Function is defined before it's called"
      }
    ])
  end

  test "does not warn for correct ordering" do
    """
    defmodule App.File do
      def test() do
        IO.inspect("IN HERE")
        test_2()
      end

      def test_2(), do: test_3()

      def test_3(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([])

    """
    defmodule App.File do
      def recursive(%{do_it: true}) do
        do_recursive()
      end

      def recursive(args) do
        args
        |> Map.put(:do_it, true)
        |> recursive()
      end

      def do_recurisve(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([])
  end

  test "does not warn with nested modules correct ordering" do
    """
    defmodule App.File do
      defmodule Sub do
        def run(args), do: args
      end

      def test() do
        IO.inspect("IN HERE")
        test_2()
      end

      def test_2(), do: test_3()

      def test_3(), do: Sub.run(:ok)
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([])

    """
    defmodule App.File do
      def recursive(%{do_it: true}) do
        do_recursive()
      end

      def recursive(args) do
        args
        |> Map.put(:do_it, true)
        |> recursive()
      end

      def do_recurisve(), do: :ok
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([])
  end

  test "does not warn with variables matching function names" do
    """
    defmodule App.File do
      def test() do
        test_2()
      end

      def test_2(), do: test_3()

      def test_3(), do: Sub.run(:ok)

      def do_test(test) do
        test
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> FileTopToBottom.run([])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
