defmodule Jux.State do

  @moduledoc """
  The complete state of the runtime system:

  - dictionary
  - parameter stack (not yet called functions)
  - return stack (calculated results)
  - mode
  """
  defstruct dictionary: nil, stack: [], instruction_queue: EQueue.new, unparsed_program: "", mode: :runtime

  def new(source, stack \\ []) do
    %__MODULE__{unparsed_program: source, stack: stack, dictionary: setup_dictionary}
  end

  alias Jux.Primitive

  def setup_dictionary do
    %Jux.Dictionary{}
    |> add_primitive("puts", &Primitive.puts/1)
    |> add_primitive("dup", &Primitive.dup/1)
    |> add_primitive("pop", &Primitive.pop/1)
    |> add_primitive("swap", &Primitive.swap/1)

    |> add_primitive("[", &Primitive.build_quotation/1, fn state -> compile(state, Jux.Quotation.new) end)
    |> add_primitive("]", &Primitive.noop/1, &Primitive.end_compilation/1)

    |> add_primitive("define_new_word", &Primitive.define_new_word/1)
    |> add_primitive("rename_last_word", &Primitive.rename_last_word/1)
    |> add_primitive("heave_token", &Primitive.heave_token_to_string/1)
    |> add_primitive("heave_quotation", &Primitive.heave_quotation/1)

    |> add_primitive("add", &Primitive.add/1)
    |> add_primitive("nand", &Primitive.nand/1)

    |> add_primitive("dump_state", &Primitive.dump_state/1)
    |> add_primitive("dump_stack", &Primitive.dump_stack/1)
  end

  defp add_primitive(dictionary, name, function, compile_time_function \\ nil) do
    compile_time_function =
    if compile_time_function == nil do
      fn state -> Primitive.noop_compilation(name, state) end
    else
      compile_time_function
    end
    dictionary
    |> Jux.Dictionary.define_new_word([function], [compile_time_function])
    |> Jux.Dictionary.rename_last_word(name)
  end

  defp add_complex(dictionary, name, implementation) do
    compiled_implementation =
      implementation
      |> Enum.map(fn name -> get_reference!(dictionary, name) end)

    dictionary
    |> Jux.Dictionary.define_new_word(compiled_implementation)
    |> Jux.Dictionary.rename_last_word(name)
  end

  def call(state = %__MODULE__{}) do
    case next_word(state) do
      :done ->
        IO.puts "Execution finished"
        state
      {word, state} ->
        if is_function(word) do
          word.(state)
          |> call
        else
          {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word)
          state
          |> add_impl_to_instruction_queue(impl)
          |> call # Tail recurse
        end
    end
  end

  def add_impl_to_instruction_queue(state, impl) do
    new_queue = EQueue.join(EQueue.from_list(impl), state.instruction_queue)
    %__MODULE__{state | instruction_queue: new_queue}
  end

  def compile(state = %__MODULE__{}, accum) do
    case next_word(state) do
      :done ->
        raise ArgumentError, "Error: End of program reached during compilation mode. Missing `]`?"
      {word, state} ->
        if is_function(word) do
          case word.(state) do
            :done ->
              {put_in(state.mode, :runtime), accum}
            result ->
              IO.inspect(word: word, result: result)
              compile(state, Jux.Quotation.push(accum, result))
          end
        else
          {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word, :compiletime)
          IO.inspect(impl)
          state
          |> add_impl_to_instruction_queue(impl)
          |> compile(accum)
        end
    end
  end

  @doc """
  Fetches the next word, by taking it from the instruction queue,
  or, if the instruction queue is empty, from the unparsed program directly.
  """
  def next_word(state)

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}, unparsed_program: ""}) do
    :done
  end

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}, unparsed_program: unparsed_program}) do
    {token, rest} = Jux.Parser.extract_token(unparsed_program)
    compiled_token = Jux.Compiler.compile_token(token, state.dictionary, state.mode)

    new_state =
      state
      |> Map.put(:unparsed_program, rest)
    {compiled_token, new_state}
    # |> Map.put(:instruction_queue, EQueue.from_list([compiled_token]))
    # state
    # |> Jux.Parser.extract_token
    # |> do_next_word
  end

  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:value, word, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    {word, Map.put(state, :instruction_queue, new_instruction_queue)}
  end

  # def next_compiletime_word(state = %__MODULE__{}) do
  #   {token, rest} = Jux.Parser.extract_token(state.unparsed_program)
  #   compiled_token = Jux.Compiler.compile_token(token, state.dictionary)
  #   new_state =
  #     state
  #     |> Map.put(:unparsed_program, rest)
  #   {compiled_token, new_state}
  # end

end
