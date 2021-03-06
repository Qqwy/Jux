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
    # {word, new_unparsed_program} = Jux.State.extract_token(state.unparsed_program)
    {:value, int, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    # word_int = word |> String.to_integer
    # IO.inspect({:unparsed_program, new_unparsed_program})

    state
    # |> Map.put(:unparsed_program, new_unparsed_program)
    |> Map.put(:stack, [int | state.stack])
    |> Map.put(:instruction_queue, new_instruction_queue)
  end

  # def start_quotation(state) do
  #   {quotation, unparsed_program_rest} =
  #     state.unparsed_program
  #     |> Jux.Parser.build_quotation(state.dictionary)

  #   state
  #   |> Map.put(:stack, [quotation | state.stack])
  #   |> Map.put(:unparsed_program, unparsed_program_rest)
  # end

  # Deprecated
  def create_word(state) do
    {word, unparsed_program_rest} = Jux.Parser.extract_token(state.unparsed_program)
    state
    |> Map.put(:dictionary, Jux.Dictionary.create_new_word(state.dictionary, word))
    |> Map.put(:unparsed_program, unparsed_program_rest)
    |> IO.inspect
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

  def alter_implementation_of_newest_word(state) do
    # [quotation | stack] = state.stack
    # {"[", unparsed_program_rest} = Jux.Parser.extract_token(state.unparsed_program)
    # {quotation, unparsed_program_rest} = Jux.Parser.build_quotation(unparsed_program_rest, state.dictionary)
    {quotation, queue} = state.instruction_queue

    dictionary = Jux.Dictionary.alter_implementation_of_newest_word(state.dictionary, quotation |> Jux.Quotation.implementation)

    state
    |> Map.put(:dictionary, dictionary)
    |> Map.put(:instruction_queue, queue)
    # |> Map.put(:stack, stack)
    # |> Map.put(:unparsed_program, unparsed_program_rest)
    # |> IO.inspect
  end

  def execute_quotation(state) do
    [quotation | stack] = state.stack
    implementation =
      quotation
      |> Jux.Quotation.implementation
      |> Enum.flat_map(fn token -> Jux.Compiler.compile_token(token, state.dictionary) end)

    new_instruction_queue = EQueue.join(implementation |> EQueue.from_list, state.instruction_queue)

    state
    |> Map.put(:instruction_queue, new_instruction_queue)
    |> Map.put(:stack, stack)
  end

  # DEBUG. will be removed at some point (?)
  def dump_state(state) do
    state
    |> IO.inspect
  end
  def dump_stack(state) do
    IO.puts "bottom >>> [ " <> (state.stack |> Enum.reverse |> Enum.map(&inspect/1) |> Enum.join(" ")) <> " ] <<< top"
    state
  end
end
