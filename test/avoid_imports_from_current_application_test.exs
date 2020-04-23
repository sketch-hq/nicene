defmodule Nicene.AvoidImportsFromCurrentApplicationTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.AvoidImportsFromCurrentApplication

  test "finds issues" do
    """
    defmodule App.File do
      alias AppWeb.Api

      import Api.Helpers

      import App.Helpers

      def test() do
        get_response()
        handle_event()
        :ok
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AvoidImportsFromCurrentApplication.run(namespaces: [App, AppWeb])
    |> assert_issues([
      %Issue{
        category: :refactoring,
        check: AvoidImportsFromCurrentApplication,
        filename: "lib/app/file.ex",
        line_no: 4,
        message: "Import from configured namespaces found"
      },
      %Issue{
        category: :refactoring,
        check: AvoidImportsFromCurrentApplication,
        filename: "lib/app/file.ex",
        line_no: 6,
        message: "Import from configured namespaces found"
      }
    ])
  end

  test "doesn't have false positives" do
    """
    defmodule App.File do
      alias AppWeb.Api

      import Api.Helpers

      import App.Helpers

      def test() do
        get_response()
        handle_event()
        :ok
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AvoidImportsFromCurrentApplication.run(namespaces: [Apple, AppleWeb])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
