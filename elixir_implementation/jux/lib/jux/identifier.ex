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
  def evaluate(identifier, stack, fun_queue, known_definitions) do
    #IO.inspect(identifier.name)
    #IO.inspect(known_definitions)
    #IO.inspect(known_definitions[identifier])

    identifier_atom = identifier.name |> Jux.Helper.safe_to_existing_atom
    cond do
      identifier_atom != 0 && Jux.Primitive.__info__(:functions)[identifier_atom] == 2 ->
        {apply(Jux.Primitive, identifier_atom, [stack, known_definitions]), fun_queue}
      # identifier_atom != 0 && Jux.Fallback.__info__(:functions)[identifier_atom] == 1 ->
      #   {stack, apply(Jux.Fallback, identifier_atom, [fun_queue])}
      known_definitions[identifier.name] != nil ->
        {stack, known_definitions[identifier.name] ++ fun_queue}
      :otherwise ->
        IO.inspect(Jux.stack_to_string(stack))
        IO.inspect(fun_queue)
        raise "Undefined identifier `#{identifier.name}`."
    end
  end

  @doc """
  Used to completely flatten a fallback function's implementation, so we don't have to use rewrite rules multiple times,
  but only for the initial high-level invocation.

  This can be done because during execution, the built-in functions that our implementation supports do not change.
  """
  def fully_expand(function_stack, known_definitions \\ %{}) do
    do_fully_expand(:lists.reverse(function_stack), [], known_definitions)
  end

  defp do_fully_expand([], result, known_definitions), do: result
  defp do_fully_expand([identifier = %Jux.Identifier{name: "__PRIMITIVE__"} | rest], result, known_definitions) do
    do_fully_expand(rest, [identifier | result], known_definitions)
  end
  defp do_fully_expand([identifier = %Jux.Identifier{} | rest], result, known_definitions) do
    Code.ensure_loaded(Jux.Primitive)
    identifier_atom = identifier.name |> Jux.Helper.safe_to_existing_atom
    cond do
      identifier_atom != 0 && Jux.Primitive.__info__(:functions)[identifier_atom] == 2 ->
        do_fully_expand(rest, [identifier | result], known_definitions)
      # identifier_atom != 0 &&Jux.Fallback.__info__(:functions)[identifier_atom] == 1 ->
      #   do_fully_expand(apply(Jux.Fallback, identifier_atom, [rest]), result, known_definitions)
      known_definitions[identifier.name] != nil ->
        do_fully_expand(known_definitions[identifier.name] ++ rest, result, known_definitions)
      :otherwise ->
        IO.inspect(Jux.stack_to_string(result))
        IO.inspect(Jux.stack_to_string(rest))
        raise "Undefined identifier `#{identifier.name}`."
    end
  end
  defp do_fully_expand([literal | rest], result, known_definitions), do: do_fully_expand(rest, [literal | result], known_definitions)


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
