defmodule Nicene.EctoSchemaDirectoriesTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.EctoSchemaDirectories

  test "warns if there are non-schemas in the same directory as schemas" do
    other_files = [
      """
      defmodule My.Admin do
        use Ecto.Schema

        schema "admins" do
          field(:name, :string)
        end
      end
      """,
      """
      defmodule My.Users do

        alias My.{Repo, User}

        def list_all() do
          Repo.all(User)
        end
      end
      """
    ]

    """
    defmodule My.User do
      use Ecto.Schema

      schema "users" do
        field(:name, :string)
      end
    end
    """
    |> SourceFile.parse("lib/my/user.ex")
    |> EctoSchemaDirectories.run([], other_files)
    |> assert_issues([
      %Issue{
        category: :refactoring,
        check: EctoSchemaDirectories,
        filename: "lib/my/user.ex",
        message: "lib/my/user.ex is in a directory with files that are not Ecto schemas"
      }
    ])
  end

  test "does not warn if there are only Ecto schemas in the directory" do
    other_files = [
      """
      defmodule My.Admin do
        use Ecto.Schema

        schema "admins" do
          field(:name, :string)
        end
      end
      """,
      """
      defmodule My.Member do
        use Ecto.Schema

        schema "members" do
          field(:name, :string)
        end
      end
      """
    ]

    """
    defmodule My.User do
      use Ecto.Schema

      schema "users" do
        field(:name, :string)
      end
    end
    """
    |> SourceFile.parse("lib/my/user.ex")
    |> EctoSchemaDirectories.run([], other_files)
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
