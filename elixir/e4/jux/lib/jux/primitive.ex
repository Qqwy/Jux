defmodule Jux.Primitive do
  alias Jux.State


  def noop(state), do: state

  def push(state, value) do
    stack = State.get_stack(state)
    State.update_stack(state, [value | stack])
  end

  def dup(state) do
    [n | stack] = State.get_stack(state)
    State.update_stack(state, [n, n | stack])
  end

  def pop(state) do
    [_ | stack] = State.get_stack(state)
    State.update_stack(state, stack)
  end

  def swap(state) do
    [a, b | rest] = State.get_stack(state)
    State.update_stack(state, [b, a | rest])
  end

  def puts(state) do
    [n | stack ] = State.get_stack(state)
    IO.puts(n)
    State.update_stack(state, stack)
  end

  @doc """

  Runs the quotation on top, hiding the penultimate value for the time being.
  After this puts this value below that back on top of the stack.

  This is done by adding the quotation's implementation, followed by a 'push_lit' function
  to the instruction queue.
  """
  def dip(state) do
    [quotation , n | stack] = State.get_stack(state)
    push_lit = fn state ->
      new_stack = State.get_stack(state)
      State.update_stack(state, [n | new_stack])
    end
    IO.inspect({quotation, stack})
    quot_impl =
      quotation
      |> Jux.Quotation.compiled_implementation
      |> EQueue.from_list
    impl = EQueue.join(quot_impl, EQueue.from_list([push_lit]))

    state
    |> State.update_stack(stack)
    # |> Map.put(:stack, stack)
    # |> Map.put(:instruction_queue, EQueue.join(impl, state.instruction_queue))
    |> State.update_iq(EQueue.join(impl, State.get_iq(state)))
  end

  def start_compilation(state) do
    count = Jux.Dictionary.definition_count(state.dictionary)

    state
    |> State.push_mode(:compiletime)
    |> State.create_new_stack
    |> State.create_new_iq
  end

  def end_compilation(state) do
    state
    |> State.drop_newest_iq
    |> State.newest_stack_to_quotation
    |> State.pop_mode(:compiletime)
  end

  def heave_quotation(state) do
    IO.inspect(heaving_quotation_of: state)
    case Jux.Parser.extract_token(state.unparsed_program) do
      {"[", unparsed_rest} ->
        # unexecuted_stuff = state.instruction_queue
        # IO.inspect({"Unexecuted stuff: ", unexecuted_stuff})
        # new_state =
          state
          # |> Map.put(:instruction_queue, EQueue.new)
          |> Map.put(:unparsed_program, unparsed_rest)
          |> start_compilation

        # Map.put(new_state, :instruction_queue, EQueue.join(unexecuted_stuff, new_state.instruction_queue))

      {elem, unparsed_rest} ->
        raise ArgumentError, "heave_quotation called without quotation as next element in the unparsed program: `#{elem}` `#{unparsed_rest}`"
    end
  end

  def define_new_word(state) do
    case State.get_stack(state) do
      [quotation, compiletime_quotation | stack] ->
        count = Jux.Dictionary.definition_count(state.dictionary)
        compiled_runtime_code = Jux.Quotation.compiled_implementation(quotation)

        bootstrapped_quotation = Jux.Quotation.new() |> Jux.Quotation.push({"???#{count}", count})
        bootstrapped_compiletime_code = Jux.Quotation.unshift(compiletime_quotation, {inspect(bootstrapped_quotation), fn state -> Jux.Primitive.push(state, bootstrapped_quotation) end})
        compiled_compiletime_code = Jux.Quotation.compiled_implementation(bootstrapped_compiletime_code) |> IO.inspect
        # dictionary = Jux.Dictionary.define_new_word(state.dictionary, Jux.Quotation.compiled_implementation(quotation), Jux.Quotation.compiled_implementation(compiletime_quotation))
        dictionary = Jux.Dictionary.define_new_word(state.dictionary, compiled_runtime_code, compiled_compiletime_code)
        state
        |> Map.put(:dictionary, dictionary)
        # |> Map.put(:stack, stack)
        |> State.update_stack(stack)
      _ ->
        raise ArgumentError, "Cannot define new word because the stack does not have a quotation on top: #{inspect state.stack}"
    end
  end

  def rename_last_word(state) do
    case State.get_stack(state) do
      [name | stack] when is_binary(name) ->
        dictionary = Jux.Dictionary.rename_last_word(state.dictionary, name)
        state
        |> Map.put(:dictionary, dictionary)
        |> State.update_stack(stack)
        # |> Map.put(:stack, stack)
      _ ->
        raise ArgumentError, "Cannot rename last word because the stack does not have a string on top: #{inspect State.get_stack(state)}"
    end
  end

  def heave_token_to_string(state) do
    {word, unparsed_rest} = Jux.Parser.extract_token(state.unparsed_program)
    stack = State.get_stack(state)
    state
    |> Map.put(:unparsed_program, unparsed_rest)
    |> State.update_stack([word | stack])
  end

  def add(state) do
    case State.get_stack(state) do
      [lhs, rhs | rest] when is_integer(lhs) and is_integer(rhs) ->
        stack = [lhs + rhs | rest]
        State.update_stack(state, stack)
      _ ->
        raise ArgumentError, "Less than two arguments on the stack, or one or both are not integers"
    end
  end

  def nand(state) do
    case State.get_stack(state) do
      [lhs, rhs | rest] ->
        nand_result = !(lhs && rhs)
        stack = [nand_result | rest]
        State.update_stack(state, stack)
      _ ->
        raise ArgumentError, "Less than two arguments on the stack"
    end
  end

  def bnand(state) do
    case State.get_stack(state) do
      [lhs, rhs | rest] ->
        bnand_result = Bitwise.band(lhs, rhs) |> Bitwise.bnot
        stack = [bnand_result | rest]
        State.update_stack(state, stack)
      _ ->
        raise ArgumentError, "Less than two arguments on the stack"
    end
  end

  def ifte(state) do
    case State.get_stack(state) do
      [else_quot, then_quot, condition_bool | rest] ->
        quot =
        if condition_bool !== false do
          then_quot
        else
          else_quot
        end
        compiled_quot =
          quot
          |> Jux.Quotation.compiled_implementation
          |> EQueue.from_list

        state
        |> State.update_stack(rest)
        |> State.update_iq(EQueue.join(compiled_quot, State.get_iq(state)))
      _ ->
        raise ArgumentError, "Less than three arguments on the stack"
    end
  end

  # Used for nearly all words:
  # Compilation behaviour = adding the runtime behaviour word reference to the top of the stack.
  # Equivalent to Forth's `,`
  # TODO: Make safe for words whose name is not yet known.
  # def straightforward_compilation(word, state) do
  #   push(state, {word, Jux.Compiler.compile_token(word, state.dictionary, :runtime)})
  # end

  def simple_compilation(state) do
    count = Jux.Dictionary.definition_count(state.dictionary)
    # runtime_fun = fn state ->
    #   rf2 = fn state -> 
    #     push(state, count)
    #   end
    #   push(state, {"???", rf2})
    # end
    # push(state, {"???", runtime_fun})
    push(state, {"???", count})
    |> IO.inspect
  end

  # DEBUGGING ONLY. Not part of the official protocol.
  def dump_state(state) do
    state
    |> IO.inspect
  end

  def dump_stack(state) do
    stack = State.get_stack(state)
    IO.puts "bottom >>> [ " <> (stack |> Enum.reverse |> Enum.map(&inspect(&1, state: state)) |> Enum.join(" ")) <> " ] <<< top"
    state
  end

  def dump_stack_nasty(state) do
    stack = State.get_stack(state)
    IO.inspect(stack, structs: false)
    state
  end
end
