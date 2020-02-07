defmodule Nicene.PublicFunctionsFirstTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.PublicFunctionsFirst

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

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
