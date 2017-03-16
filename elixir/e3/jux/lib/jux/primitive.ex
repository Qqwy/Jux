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
    [quotation | stack] = state.stack
    dictionary = Jux.Dictionary.define_new_word(state.dictionary, quotation |> Jux.Quotation.implementation)
    state
    |> Map.put(:dictionary, dictionary)
    |> Map.put(:stack, stack)
  end

  def rename_last_word(state) do
    # [name | stack] = state.stack
    stack = state.stack
    dictionary = Jux.Dictionary.rename_last_word(state.dictionary, "foo")
    state
    |> Map.put(:dictionary, dictionary)
    |> Map.put(:stack, stack)
  end

end
