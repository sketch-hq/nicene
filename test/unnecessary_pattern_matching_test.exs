defmodule Nicene.UnnecessaryPatternMatchingTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Nicene.UnnecessaryPatternMatching

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

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
