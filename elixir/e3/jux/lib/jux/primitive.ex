defmodule Jux.Primitive do
  def noop(state), do: state

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

  @doc """

  Runs the quotation on top, hiding the penultimate value for the time being.
  After this puts this value below that back on top of the stack.

  This is done by adding the quotation's implementation, followed by a 'push_lit' function
  to the instruction queue.
  """
  def dip(state) do
    [quotation , n | stack] = state.stack
    push_lit = fn state ->
      state
      |> Map.put(:stack, [n | state.stack])
    end
    quot_impl =
      quotation
      |> Jux.Quotation.compiled_implementation
      |> EQueue.from_list
    impl = EQueue.join(quot_impl, EQueue.from_list([push_lit]))

    state
    |> Map.put(:stack, stack)
    |> Map.put(:instruction_queue, EQueue.join(impl, state.instruction_queue))
  end

  def build_quotation(state) do
    # {quotation, unparsed_rest} = Jux.Parser.parse_quotation(state.unparsed_program)

    # state
    # |> Map.put(:unparsed_program, unparsed_rest)
    # |> Map.put(:stack, [quotation | state.stack])
    state = Map.put(state, :mode, :compiletime)
    {state, quotation} = Jux.State.compile(state, Jux.Quotation.new)
    state
    |> Map.put(:mode, :runtime)
    |> Map.put(:stack, [quotation | state.stack])
  end

  def end_compilation(state) do
    :done
  end

  def heave_quotation(state) do
    case Jux.Parser.extract_token(state.unparsed_program) do
      {"[", unparsed_rest} ->
        unexecuted_stuff = state.instruction_queue
        new_state =
          state
          |> Map.put(:instruction_queue, EQueue.new)
          |> Map.put(:unparsed_program, unparsed_rest)
          |> build_quotation

        Map.put(new_state, :instruction_queue, EQueue.join(new_state.instruction_queue, unexecuted_stuff))

        # {quotation, unparsed_rest} = Jux.Parser.parse_quotation(unparsed_rest)
        # state
        # |> Map.put(:unparsed_program, unparsed_rest)
        # |> Map.put(:stack, [quotation | state.stack])
      {_, unparsed_rest} ->
        raise ArgumentError, "heave_quotation called without quotation as next element in the unparsed program"
    end
  end

  def define_new_word(state) do
    case state.stack do
      [quotation , compiletime_quotation | stack] ->
        dictionary = Jux.Dictionary.define_new_word(state.dictionary, Jux.Quotation.compiled_implementation(quotation), Jux.Quotation.compiled_implementation(compiletime_quotation))
        state
        |> Map.put(:dictionary, dictionary)
        |> Map.put(:stack, stack)
      _ ->
        raise ArgumentError, "Cannot define new word because the stack does not have a quotation on top: #{inspect state.stack}"
    end
  end

  def rename_last_word(state) do
    case state.stack do
      [name | stack] when is_binary(name) ->
        dictionary = Jux.Dictionary.rename_last_word(state.dictionary, name)
        state
        |> Map.put(:dictionary, dictionary)
        |> Map.put(:stack, stack)
      _ ->
        raise ArgumentError, "Cannot rename last word because the stack does not have a string on top: #{inspect state.stack}"
    end
  end

  def heave_token_to_string(state) do
    {word, unparsed_rest} = Jux.Parser.extract_token(state.unparsed_program)
    stack = [word | state.stack]
    state
    |> Map.put(:unparsed_program, unparsed_rest)
    |> Map.put(:stack, stack)
  end

  def add(state) do
    case state.stack do
      [lhs, rhs | rest] when is_integer(lhs) and is_integer(rhs) ->
        stack = [lhs + rhs | rest]
        Map.put(state, :stack, stack)
      _ ->
        raise ArgumentError, "Less than two arguments on the stack, or one or both are not integers"
    end
  end

  def nand(state) do
    case state.stack do
      [lhs, rhs | rest] ->
        nand_result = !(lhs && rhs)
        stack = [nand_result | rest]
        Map.put(state, :stack, stack)
      _ ->
        raise ArgumentError, "Less than two arguments on the stack"
    end
  end

  def noop_compilation(word, state) do
    {word, Jux.Compiler.compile_token(word, state.dictionary, :runtime)}
  end

  # DEBUGGING ONLY. Not part of the official protocol.
  def dump_state(state) do
    state
    |> IO.inspect
  end

  def dump_stack(state) do
    IO.puts "bottom >>> [ " <> (state.stack |> Enum.reverse |> Enum.map(&inspect/1) |> Enum.join(" ")) <> " ] <<< top"
    state
  end

end
