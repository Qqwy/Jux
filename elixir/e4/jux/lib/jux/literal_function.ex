defmodule Jux.LiteralFunction do
  defstruct [:name, :impl]

  def new(name, impl) do
    %__MODULE__{impl: impl, name: name}
  end

  defimpl Inspect do
    def inspect(literal_function, _) do
      literal_function.name
    end
  end
end
