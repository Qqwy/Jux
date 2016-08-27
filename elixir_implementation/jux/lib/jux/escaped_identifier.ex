defmodule Jux.EscapedIdentifier do
  defstruct [:name]

  def new(name) do
    %__MODULE__{name: name |> to_string}
  end

  defimpl Inspect do
    def inspect(identifier, _opts) do
      "/#{identifier.name}"
    end
  end

  defimpl String.Chars do
    def to_string(identifier) do
      "/#{identifier.name}"
    end
  end

end
