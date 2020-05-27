defmodule Nicene.AliasImportGroupingTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.AliasImportGrouping

  test "finds issues at the top level" do
    """
    defmodule App.File do
      import Ecto.Query

      use Ecto.Schema

      require Logger

      alias AppWeb.{Api, Grouping}
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AliasImportGrouping.run()
    |> assert_issues([
      %Issue{
        category: :readability,
        check: Nicene.AliasImportGrouping,
        filename: "lib/app/file.ex",
        line_no: 4,
        message: "use must appear before import"
      },
      %Issue{
        category: :readability,
        check: Nicene.AliasImportGrouping,
        filename: "lib/app/file.ex",
        line_no: 8,
        message: "alias must appear before require"
      }
    ])
  end

  test "does not find an issue when everything is in order" do
    """
    defmodule App.File do
      use Ecto.Schema

      import Ecto.Query

      alias AppWeb.{Api, Grouping}

      require Logger
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AliasImportGrouping.run()
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
