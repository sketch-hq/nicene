# Nicene

Nicene is a collection of Credo checks.

Documentation is available at [https://hexdocs.pm/nicene](https://hexdocs.pm/nicene).

## Installation

Add `nicene` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nicene, "~> 0.7.0"}
  ]
end
```

## Usage

Nicene defines `Credo.Check`s that you can add to your `.credo.exs`, for
example:

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Nicene.FileAndModuleName, []},
        {Nicene.UnnecessaryPatternMatching, []},
        {Nicene.FileTopToBottom, []},
      ]
    }
  ]
}
```

See the documentation on [hex](https://hexdocs.pm/nicene) for the list of
supported checks and their configuration.
