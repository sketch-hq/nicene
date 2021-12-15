defmodule Nicene do
  @moduledoc false

  @deprecated """
  Using Nicene as a plugin is deprecated as of 0.6.0. List the checks you would
  like to use explicitly in your .credo.exs"
  """
  def init(exec), do: exec
end
