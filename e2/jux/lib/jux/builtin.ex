defmodule Jux.Builtin do

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

  def lit_int(state) do
    # [word, new_unparsed_program] = Jux.State.extract_token(state.unparsed_program)
    {:value, int, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    # word_int = word |> String.to_integer
    # IO.inspect({:unparsed_program, new_unparsed_program})

    state
    # |> Map.put(:unparsed_program, new_unparsed_program)
    |> Map.put(:stack, [int | state.stack])
    |> Map.put(:instruction_queue, new_instruction_queue)
  end

  def start_quotation(state) do
    {quotation, unparsed_program_rest} =
      state.unparsed_program
      |> Jux.Parser.build_quotation

    state
    |> Map.put(:stack, [quotation | state.stack])
    |> Map.put(:unparsed_program, unparsed_program_rest)
  end


  def dump_state(state) do
    state
    |> IO.inspect
  end
  def dump_stack(state) do
    IO.inspect state.stack
    state
  end
end
