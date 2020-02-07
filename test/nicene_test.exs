defmodule NiceneTest do
  use Assertions.Case, async: true

  alias Credo.{Issue, SourceFile}

  alias Nicene.{
    ConsistentFunctionDefinitions,
    FileAndModuleName,
    FileTopToBottom,
    NoSpecsPrivateFunctions,
    PublicFunctionsFirst,
    TestsInTestFolder,
    TrueFalseCaseStatements,
    UnnecessaryPatternMatching
  }

  describe "ConsistentFunctionDefinition" do
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
  end

  describe "FileAndModuleName" do
    test "warns for incorrect names" do
      """
      defmodule App.File do
        def test(), do: :ok
      end

      defmodule Other.Module do
        def test(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/my/file.ex")
      |> FileAndModuleName.run([])
      |> assert_issues([
        %Issue{
          category: :warning,
          check: FileAndModuleName,
          filename: "lib/app/my/file.ex",
          line_no: 5,
          message:
            "Other.Module is not definied in the correct file - should be lib/other/module.ex"
        },
        %Credo.Issue{
          category: :warning,
          check: FileAndModuleName,
          filename: "lib/app/my/file.ex",
          line_no: 1,
          message: "App.File is not definied in the correct file - should be lib/app/file.ex"
        }
      ])

      """
      defmodule App.FileTest do
        def test(), do: :ok
      end
      """
      |> SourceFile.parse("test/app/my/file_test.exs")
      |> FileAndModuleName.run([])
      |> assert_issues([
        %Issue{
          category: :warning,
          check: FileAndModuleName,
          filename: "test/app/my/file_test.exs",
          line_no: 1,
          message:
            "App.FileTest is not definied in the correct file - should be test/app/file_test.exs"
        }
      ])
    end

    test "does not warn for correct names" do
      """
      defmodule App.File do
        def test(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> FileAndModuleName.run([])
      |> assert_issues([])

      """
      defmodule App.FileTest do
        def test(), do: :ok
      end
      """
      |> SourceFile.parse("test/app/file_test.exs")
      |> FileAndModuleName.run([])
      |> assert_issues([])
    end
  end

  describe "FileTopToBottom" do
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
  end

  describe "NoSpecsPrivateFunctions" do
    test "warns with a spec on a private function" do
      """
      defmodule App.File do
        defp test_2(), do: test_3()

        @spec test() :: :ok
        def test(), do: test_2()

        @spec test_3() :: :ok
        defp test_3(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> NoSpecsPrivateFunctions.run([])
      |> assert_issues([
        %Issue{
          category: :design,
          check: NoSpecsPrivateFunctions,
          filename: "lib/app/file.ex",
          line_no: 8,
          message: "Private functions should not have @spec annotations"
        }
      ])
    end

    test "does not warn with specs on public functions" do
      """
      defmodule App.File do
        defp test_2(), do: test_3()

        @spec test() :: :ok
        def test(), do: test_2()

        defp test_3(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> NoSpecsPrivateFunctions.run([])
      |> assert_issues([])
    end

    test "does not accidentally warn with no spec" do
      ~S"""
        defmodule Mix.Tasks.Credo.Ci do
          @moduledoc "\""
          Runs Credo in CI with somewhat special behavior.

          If the branch being tested is `master`, it runs Credo on all files but with the default
          configuration, meaning that it won't fail with several of the checks that we're working
          towards fixing across the codebase.

          Otherwise, it only runs Credo on the files that have changed since the last merge commit,
          and it will fail CI if any check doesn't pass for those specific files.
          "\""

          use Mix.Task

          @shortdoc "Run Credo only on files that have changed since the last merge commit."

          @impl true
          def run(_) do
            if System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"]) == {"master", 0} do
              Mix.Task.run("credo", [])
            else
              {last_merge, 0} =
                System.cmd("git", [
                  "log",
                  "--pretty=format:%C(auto)%h",
                  "--date-order",
                  "--merges",
                  "-1"
                ])

              {diff, 0} = System.cmd("git", ["diff", "--name-only", last_merge])

              run_files(diff, "lib/", "new_files")
              run_files(diff, "test/", "new_test_files")
            end
          end

          defp run_files(diff, pattern, config_name) do
            files =
              diff
              |> String.split("\n")
              |> Enum.filter(&(&1 =~ pattern))
              |> Enum.flat_map(&["--files-included", &1])

            unless files == [] do
              Mix.Task.run("credo", ["-C", config_name | files])
            end
          end
        end
      """
      |> SourceFile.parse("lib/mix/tasks/credo.ci.ex")
      |> NoSpecsPrivateFunctions.run([])
      |> assert_issues([])
    end
  end

  describe "PublicFunctionsFirst" do
    test "warns with a private function defined before a public function" do
      """
      defmodule App.File do
        defp test_2(), do: test_3()

        def test(), do: test_2()

        defp test_3(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> PublicFunctionsFirst.run([])
      |> assert_issues([
        %Issue{
          category: :readability,
          check: PublicFunctionsFirst,
          filename: "lib/app/file.ex",
          line_no: 2,
          message: "Private function is defined before a public function"
        }
      ])
    end

    test "does not warn for correct ordering" do
      """
      defmodule App.File do
        def test(), do: test_2()

        defp test_2(), do: test_3()

        defp test_3(), do: :ok
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> PublicFunctionsFirst.run([])
      |> assert_issues([])

      ~S"""
      defmodule Graphql.Types.Error do
        use Absinthe.Schema.Notation

        object :error do
          field :code, :string do
            resolve(fn parent, _, _ -> missing_code(parent) end)
          end
        end

        defp missing_code(_) do
          {:ok, "UNKNOWN"}
        end
      end
      """
      |> SourceFile.parse("lib/app/macro_file.ex")
      |> PublicFunctionsFirst.run([])
      |> assert_issues([])
    end

    test "does not raise an exception with no function calls" do
      """
      defmodule App.File do
        use Ecto.Schema

        schema("users") do
          field(:name, :string)
        end
      end
      """
      |> SourceFile.parse("lib/app/file.ex")
      |> PublicFunctionsFirst.run([])
      |> assert_issues([])
    end
  end

  describe "TestsInTestFolder" do
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
  end

  describe "TrueFalseCaseStatements" do
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
  end

  describe "UnnecessaryPatternMatching" do
    test "warns if we're using case statements instead of if statements" do
      expected_issues = [
        %Issue{
          category: :design,
          check: UnnecessaryPatternMatching,
          filename: "lib/app/file_test.ex",
          line_no: 2,
          message: "Unnecessary pattern matching or guard clause detected"
        },
        %Issue{
          category: :design,
          check: UnnecessaryPatternMatching,
          filename: "lib/app/file_test.ex",
          line_no: 6,
          message: "Unnecessary pattern matching or guard clause detected"
        }
      ]

      """
      defmodule App.FileTest do
        def test(%{} = arg) do
          Map.keys(arg)
        end

        def test(%{} = arg, _opts) do
          Map.keys(arg)
        end
      end
      """
      |> SourceFile.parse("lib/app/file_test.ex")
      |> UnnecessaryPatternMatching.run([])
      |> assert_issues(expected_issues)
    end

    test "does not warn for correct pattern matching usage" do
      """
      defmodule App.FileTest do
        def test(%{} = arg) do
          Map.keys(arg)
        end

        def test(arg) do
          {:error, :should_be_a_map}
        end
      end
      """
      |> SourceFile.parse("test/app/file_test.ex")
      |> UnnecessaryPatternMatching.run([])
      |> assert_issues([])
    end

    test "does not error" do
      """
        defmodule Sketchql.CreditUtils do
          alias Sketchql.Credits.Credit

          def gen_credit_amount do
            min = Credit.const_min_amount() - 1
            max = Credit.const_max_amount() - 1

            Faker.random_between(min, max)
          end
        end
      """
      |> SourceFile.parse("test/app/file_test.ex")
      |> UnnecessaryPatternMatching.run([])
      |> assert_issues([])
    end
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
