# Nicene

Nicene is a collection of Credo checks.

Documentation is available at [https://hexdocs.pm/nicene](https://hexdocs.pm/nicene).

## Installation

Add `nicene` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nicene, "~> 0.1.0"}
  ]
end
```

## Usage

Add Nicene as a Credo plugin with the following line to your `.credo.exs`
file:

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [{Nicene, []}]
    }
  ]
}
```

If you want to customize any checks in Nicene, you can do that as you would
with the default Credo checks. Checks in Nicene do not take any parameters
other than the default ones offered by all Credo checks.

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Nicene.FileAndModuleName, [exit_status: 0]},
        {Nicene.UnnecessaryPatternMatching, [exit_status: 0]},
        {Nicene.FileTopToBottom, [exit_status: 0]},
        {Nicene.PublicFunctionsFirst, [exit_status: 0]},
        {Nicene.ConsistentFunctionDefinitions, [exit_status: 0]},
        {Nicene.TrueFalseCaseStatements, [exit_status: 0]},
        {Nicene.TestsInTestFolder, [exit_status: 0]},
        {Nicene.NoSpecsPrivateFunctions, [exit_status: 0]}
      ]
    }
  ]
}
```

