defmodule Nicene.AvoidForbiddenNamespacesTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.AvoidForbiddenNamespaces

  test "finds issues" do
    """
    defmodule App.File do
      alias AppWeb.Api

      def test() do
        AppWeb.Endpoint.test()
        App.Test.test()
        Other.test()
        AppMobile.Notification.test()
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AvoidForbiddenNamespaces.run(from: App, forbid: [AppWeb, AppMobile])
    |> assert_issues([
      %Issue{
        category: :refactoring,
        check: AvoidForbiddenNamespaces,
        filename: "lib/app/file.ex",
        line_no: 8,
        message: "Usage of forbidden namespace found",
        trigger: AppMobile
      },
      %Issue{
        category: :refactoring,
        check: AvoidForbiddenNamespaces,
        filename: "lib/app/file.ex",
        line_no: 5,
        message: "Usage of forbidden namespace found",
        trigger: AppWeb
      },
      %Issue{
        category: :refactoring,
        check: AvoidForbiddenNamespaces,
        filename: "lib/app/file.ex",
        line_no: 2,
        message: "Usage of forbidden namespace found",
        trigger: AppWeb
      }
    ])
  end

  test "it doesn't find issues if the module is not restricted" do
    """
    defmodule App.File do
      import AppWeb.Api

      def test() do
        App.test()
      end
    end
    """
    |> SourceFile.parse("lib/app/file.ex")
    |> AvoidForbiddenNamespaces.run(from: AppWeb, forbid: [App])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
