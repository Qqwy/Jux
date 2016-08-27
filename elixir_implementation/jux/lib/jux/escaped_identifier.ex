defmodule Jux.EscapedIdentifier do
  defstruct [:name]

  def new(name) do
    %__MODULE__{name: name |> to_string}
  end
end
