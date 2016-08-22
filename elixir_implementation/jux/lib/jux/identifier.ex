defmodule Jux.Identifier do
  @moduledoc """
  An identifier that refers to a function.

  This function might be one of:
  - built in
  - not built in but part of the standard library that has a fallback implementation.
  - a custom function that was defined earlier in the program.
  """

  defstruct [:name]

  @doc """
  Creates a new identifier, identified by the given `name`.
  """
  def new(name) do
    %__MODULE__{name: name}
  end

  @doc """
  Tries to evaluate this identifier.

  - First tries to call one of the Jux.Primitive functions.
  - If these cannot be found, we look for appliable rewrite rules.
  - If these cannot be found, we look for a custom defined function. (TODO)
  - If these cannot be found either, an error is thrown as the identifier is unknown.
  """
  def evaluate(identifier, stack) do
    try do
      identifier_atom = identifier.name |> String.to_existing_atom
      cond do
        Jux.Primitive.__info__(:functions)[identifier_atom] == 1 ->
          apply(Jux.Primitive, identifier_atom, [stack])
      true ->
        raise "No implementation found for `#{identifier.name}`."
      end
    rescue 
      ArgumentError ->
        # Simply skip this lookup step if the identifier is not an existing atom.
    end
  end

  defimpl Inspect do
    def inspect(identifier, _opts) do
      identifier.name
    end
  end
end
