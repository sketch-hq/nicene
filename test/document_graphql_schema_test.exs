defmodule Nicene.DocumentGraphqlSchemaTest do
  use Assertions.Case
  import Nicene.ExpectIssues

  alias Credo.SourceFile

  alias Nicene.DocumentGraphqlSchema

  test "does not warn if everything is documented correctly" do
    ~S'''
    defmodule App.Types.User do
      scalar :time, description: "A time scalar" do
        parse &Timex.parse(&1.value, "{ISOz}")
        serialize &Timex.format!(&1, "{ISOz}")
      end

      directive :mydirective do
        description "A directive, whatever these things are"

        arg :if, non_null(:boolean), description: "Skipped when true."

        on Language.Field

        instruction fn
          %{if: true} ->
            :skip
          _ ->
            :include
        end
      end

      interface :vehicle do
        description "An interface for a vehicle"
        field :wheel_count, :integer, description: "The number of wheels"
      end

      object :rally_car do
        description "A type of car for rallying"

        field :wheel_count, :integer, description: "the number of wheels"
        interface :vehicle
      end

      union :search_result do
        description "A search result"

        types [:person, :business]
        resolve_type fn
          %Person{}, _ -> :person
          %Business{}, _ -> :business
        end
      end

      enum :share_filter_type, description: "some values in an enum" do
        value(:all, as: "all", description: "all of the things")
        value(:own, as: "own") do
          description "just our own things"
        end
      end

      input_object :share_search_input, description: "The input for searching" do
        field(:args, :arg_type, default_value: "own") do
          description """
          A heredoc description to see what's good here.
          """
        end
      end

      object :user do
        description "A user object"

        field(:identifier, :string, name: "id", description: "An identifier")
        field :projects, non_null(:projects) do
          pagination_args()
          description "Some projects"
          resolve(&ProjectResolver.list_projects/3)
        end
      end
    end
    '''
    |> SourceFile.parse("lib/app/types/user.ex")
    |> DocumentGraphqlSchema.run([])
    |> assert_issues([])
  end

  test "warns if documentation is missing or if documented with `@desc` attribute" do
    ~S'''
    defmodule App.Types.User do
      @desc "A scalar time type"
      # credo:expect-next-line
      scalar :time do
        parse &Timex.parse(&1.value, "{ISOz}")
        serialize &Timex.format!(&1, "{ISOz}")
      end

      # credo:expect-next-lines:2
      directive :mydirective do
        arg :if, non_null(:boolean)

        on Language.Field

        instruction fn
          %{if: true} ->
            :skip
          _ ->
            :include
        end
      end

      # credo:expect-next-lines:2
      interface :vehicle do
        field :wheel_count, :integer
      end

      # credo:expect-next-lines:2
      object :rally_car do
        field :wheel_count, :integer
        interface :vehicle
      end

      # credo:expect-next-line
      union :search_result do
        types [:person, :business]
        resolve_type fn
          %Person{}, _ -> :person
          %Business{}, _ -> :business
        end
      end

      # credo:expect-next-lines:3
      enum :share_filter_type do
        value(:all, as: "all")
        value(:own, as: "own")
      end

      # credo:expect-next-lines:2
      input_object :share_search_input do
        field(:args, :arg_type, default_value: "own")
      end

      # credo:expect-next-lines:2
      object :user do
        field(:identifier, :string, name: "id")

        @desc "A number of wheels on a car"
        # credo:expect-next-line
        field :projects, non_null(:projects), default: [] do
          pagination_args()
          resolve(&ProjectResolver.list_projects/3)
        end
      end
    end
    '''
    |> SourceFile.parse("lib/app/types/user.ex")
    |> assert_expected_issues(DocumentGraphqlSchema, 16)
  end

  test "does not warn for Ecto schemas (which also use `field`)" do
    ~S'''
    defmodule App.Users.User do
      use Ecto.Schema

      @type t :: %__MODULE__{}

      schema "users" do
        field(:identifier, :string)
        field(:name, :string)
        field(:percentage, :integer, default: 0)
        timestamps(inserted_at: :createdAt, updated_at: :updatedAt)
      end
    end
    '''
    |> SourceFile.parse("lib/app/users/user.ex")
    |> DocumentGraphqlSchema.run([])
    |> assert_issues([])
  end
end
