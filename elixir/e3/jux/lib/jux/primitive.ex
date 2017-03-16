defmodule Jux.Primitive do
  def dup(state) do
    [n | stack] = state.stack
    Map.put(state, :stack, [n, n | stack])
  end

  def pop(state) do
    [_ | stack] = state.stack
    Map.put(state, :stack, stack)
  end

  def swap(state) do
    [a, b | rest] = state.stack
    Map.put(state, :stack, [b, a | rest])
  end

  def puts(state) do
    [n | stack ] = state.stack
    IO.puts(n)
    Map.put(state, :stack, stack)
  end

  def define_new_word(state) do
    case state.stack do
      [quotation | stack] ->
        dictionary = Jux.Dictionary.define_new_word(state.dictionary, quotation |> Jux.Quotation.implementation)
        state
        |> Map.put(:dictionary, dictionary)
        |> Map.put(:stack, stack)
      _ ->
        raise ArgumentError, "Cannot define new word because the stack does not have a quotation on top: #{inspect stack}"
  end

  def rename_last_word(state) do
    case state.stack do
      [name | stack] when is_string(name) ->
        dictionary = Jux.Dictionary.rename_last_word(state.dictionary, name)
        state
        |> Map.put(:dictionary, dictionary)
        |> Map.put(:stack, stack)
      _ ->
        raise ArgumentError, "Cannot rename last word because the stack does not have a string on top: #{inspect stack}"
    end
  end

  def heave_token_to_string(state) do
    {word, unparsed_rest} = Jux.Parser.extract_token(state.unparsed_program)
    stack = [word | stack]
    state
    |> Map.put(:unparsed_program, unparsed_rest)
    |> Map.put(:stack, stack)
  end

end
