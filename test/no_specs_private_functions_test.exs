defmodule Nicene.NoSpecsPrivateFunctionsTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.NoSpecsPrivateFunctions

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

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
