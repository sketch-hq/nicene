defmodule Nicene do
  @moduledoc """
  A Credo plugin which offers several additional checks.
  """

  alias Credo.Plugin

  def init(exec) do
    config_file =
      :nicene
      |> :code.priv_dir()
      |> Path.join(".credo.exs")
      |> File.read!()

    Plugin.register_default_config(exec, config_file)
  end
end
