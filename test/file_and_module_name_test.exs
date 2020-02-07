defmodule Nicene.FileAndModuleNameTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.FileAndModuleName

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

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
