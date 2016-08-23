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
    %__MODULE__{name: name |> to_string}
  end

  @doc """
  Tries to evaluate this identifier.

  - First tries to call one of the Jux.Primitive functions.
  - If these cannot be found, we look for appliable rewrite rules.
  - If these cannot be found, we look for a custom defined function. (TODO)
  - If these cannot be found either, an error is thrown as the identifier is unknown.
  """
  def evaluate(identifier, stack, fun_queue) do
    try do
      identifier_atom = identifier.name |> String.to_existing_atom
      cond do
        Jux.Primitive.__info__(:functions)[identifier_atom] == 1 ->
          {apply(Jux.Primitive, identifier_atom, [stack]), fun_queue}
        Jux.Fallback.__info__(:functions)[identifier_atom] == 1 ->
          {stack, apply(Jux.Fallback, identifier_atom, [fun_queue])}
      true ->
        raise "No implementation found for `#{identifier.name}`."
      end
    rescue 
      ArgumentError -> 
        # Simply skip this lookup step if the identifier is not an existing atom.
        raise "No implementation found for `#{identifier.name}`."
    end
  end

  @doc """
  Used to completely flatten a fallback function's implementation, so we don't have to use rewrite rules multiple times,
  but only for the initial high-level invocation.

  This can be done because during execution, the built-in functions that our implementation supports do not change.
  """
  def fully_expand(function_stack) do
    do_fully_expand(:lists.reverse(function_stack), [])
  end

  defp do_fully_expand([], result), do: result
  defp do_fully_expand([identifier = %Jux.Identifier{} | rest], result) do
    try do
      identifier_atom = identifier.name |> String.to_existing_atom
      cond do
        Jux.Primitive.__info__(:functions)[identifier_atom] == 1 ->
          do_fully_expand(rest, [identifier | result])
        Jux.Fallback.__info__(:functions)[identifier_atom] == 1 ->
          do_fully_expand(apply(Jux.Fallback, identifier_atom, [rest]), result)
      true ->
        raise "No implementation found for `#{identifier.name}`."
      end
    rescue 
      ArgumentError -> 
        # Simply skip this lookup step if the identifier is not an existing atom.
        raise "No implementation found for `#{identifier.name}`."
    end
  end
  defp do_fully_expand([literal | rest], result), do: do_fully_expand(rest, [literal | result])


  defimpl Inspect do
    def inspect(identifier, _opts) do
      identifier.name
    end
  end

  defimpl String.Chars do
    def to_string(identifier) do
      identifier.name
    end
  end
end
