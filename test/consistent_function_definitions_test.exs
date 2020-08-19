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

  test "works with macros" do
    """
    defmodule App.File.Macro do
      defmacro __using__(_) do
        names = %{test: "foo"}

        quote do
          def unquote(names.test)(%{}), do: :ok

          def unquote(names.test)(_) do
            :err
          end

          def unquote(names.test)(other) do
            :other
          end
        end
      end
    end

    defmodule App.File do
      use App.File.Macro
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 6,
        message: "Inconsistent function definition found",
        scope: "App.File.Macro.__using__",
        exit_status: 4,
        severity: 1,
        priority: 11
      },
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 10,
        message: "Inconsistent function definition found",
        scope: "App.File.Macro.__using__",
        exit_status: 4,
        severity: 1,
        priority: 11
      }
    ])
  end

  test "works with macros (2)" do
    """
    defmodule App.File.Macro2 do
      defmacro deftest(_) do
        names = %{test: "foo"}
        quote do
          def unquote(names.test)(arg) when is_map(arg), do: :ok

          def unquote(names.test)(_) do
            :err
          end

          def unquote(names.test)(other) do
            :other
          end
        end
      end
    end

    defmodule App.File do
      require App.File.Macro2

      App.File.Macro2.deftest()
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> ConsistentFunctionDefinitions.run([])
    |> assert_issues([
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 10,
        message: "Inconsistent function definition found",
      },
      %Issue{
        category: :readability,
        check: ConsistentFunctionDefinitions,
        filename: "lib/app/file.ex",
        line_no: 6,
        message: "Inconsistent function definition found",
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
