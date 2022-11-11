defmodule Nicene.DocumentEctoSchemaTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.DocumentEctoSchema

  test "does not warn if everything is documented correctly" do
    ~S'''
    defmodule App.User do
      use Ecto.Schema

      @typedoc """
      A user is a person in our system.

      ## Associations

      company - employer of the given user
      profile - public information from the user
      posts - blog posts written by the given user
      comments - comments on all blog posts written by the user
      achievements - achievements the user won
      """
      @type t :: %__MODULE__{}

      schema("users") do
        field(:name, :string)
        belongs_to(:company, Company)
        has_one(:profile, Profile)
        has_many(:posts, Post)
        has_many(:comments, through: [:posts, :comments])
        many_to_many(:achievements, Achievement, join_through: "user_achievements")
      end
    end
    '''
    |> SourceFile.parse("lib/app/user.ex")
    |> DocumentEctoSchema.run([])
    |> assert_issues([])
  end

  test "warns if one field is not documented" do
    line_numbers = [
      {"company", 15},
      {"profile", 16},
      {"posts", 17},
      {"achievements", 19}
    ]

    expected_issues =
      Enum.map(line_numbers, fn {field, line_no} ->
        %Issue{
          category: :readability,
          check: Nicene.DocumentEctoSchema,
          filename: "lib/app/user.ex",
          line_no: line_no,
          message: "Ecto association #{field} should be documented."
        }
      end)

    ~S'''
    defmodule App.User do
      use Ecto.Schema

      @typedoc """
      A user is a person in our system.

      ## Associations

      comments - comments on all blog posts written by the user
      """
      @type t :: %__MODULE__{}

      schema("users") do
        field(:name, :string)
        belongs_to(:company, Company)
        has_one(:profile, Profile)
        has_many(:posts, Post)
        has_many(:comments, through: [:posts, :comments])
        many_to_many(:achievements, Achievement, join_through: "user_achievements")
      end
    end
    '''
    |> SourceFile.parse("lib/app/user.ex")
    |> DocumentEctoSchema.run([])
    |> assert_issues(expected_issues)
  end

  test "warns if documentation is missing" do
    line_numbers = [
      {"company", 6},
      {"profile", 7},
      {"posts", 8},
      {"comments", 9},
      {"achievements", 10}
    ]

    expected_issues =
      Enum.map(line_numbers, fn {field, line_no} ->
        %Issue{
          category: :readability,
          check: Nicene.DocumentEctoSchema,
          filename: "lib/app/user.ex",
          line_no: line_no,
          message: "Ecto association #{field} should be documented."
        }
      end)

    ~S'''
    defmodule App.User do
      use Ecto.Schema

      schema("users") do
        field(:name, :string)
        belongs_to(:company, Company)
        has_one(:profile, Profile)
        has_many(:posts, Post)
        has_many(:comments, through: [:posts, :comments])
        many_to_many(:achievements, Achievement, join_through: "user_achievements")
      end
    end
    '''
    |> SourceFile.parse("lib/app/user.ex")
    |> DocumentEctoSchema.run([])
    |> assert_issues(expected_issues)
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
