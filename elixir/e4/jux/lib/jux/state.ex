defmodule Jux.State do

  @moduledoc """
  The complete state of the runtime system:

  - dictionary
  - parameter stack (not yet called functions)
  - return stack (calculated results)
  - mode
  """
  defstruct dictionary: nil, stacks: [[]], instruction_queues: [Okasaki.Queue.empty()], unparsed_program: "", mode: [:runtime]

  def new(source, stack \\ []) do
    %__MODULE__{unparsed_program: source, stacks: [stack], dictionary: setup_dictionary()}
  end

  alias Jux.Primitive

  def setup_dictionary do
    %Jux.Dictionary{}
    |> add_primitive("puts", &Primitive.puts/1)
    |> add_primitive("dup", &Primitive.dup/1)
    |> add_primitive("pop", &Primitive.pop/1)
    |> add_primitive("swap", &Primitive.swap/1)
    |> add_primitive("dip", &Primitive.dip/1)

    |> add_primitive("[", &Primitive.start_compilation/1, &Primitive.start_compilation/1)
    |> add_primitive("]", &Primitive.noop/1, &Primitive.end_compilation/1)
    |> add_primitive("simply_compileme", &Primitive.simple_compilation/1, &Primitive.noop/1)

    |> add_primitive("define_new_word", &Primitive.define_new_word/1)
    |> add_primitive("rename_last_word", &Primitive.rename_last_word/1)
    |> add_primitive("heave_token", &Primitive.heave_token_to_string/1)
    |> add_primitive("heave_quotation", &Primitive.heave_quotation/1)

    |> add_primitive("add", &Primitive.add/1)
    |> add_primitive("nand", &Primitive.nand/1)
    |> add_primitive("bnand", &Primitive.bnand/1)

    |> add_primitive("cons", &Primitive.cons/1)

    |> add_primitive("ifte", &Primitive.ifte/1)

    |> add_primitive("dump_state", &Primitive.dump_state/1)
    |> add_primitive("dump_stack", &Primitive.dump_stack/1)
    |> add_primitive("dump_stack_nasty", &Primitive.dump_stack_nasty/1)
  end

  def mode(state) do
    hd state.mode
  end

  def push_mode(state, mode) do
    Map.put(state, :mode, [mode | state.mode])
  end

  def pop_mode(state) do
    [_ | rest_modes] = state.mode
    Map.put(state, :mode, rest_modes)
  end

  def pop_mode(state, mode) do
    case state.mode do
      [mode | rest_modes] ->
        Map.put(state, :mode, rest_modes)
      _ ->
        raise ArgumentError, "Attempting to end mode `#{mode}`, but the Jux state is not currently in this mode."
    end
  end

  def get_stack(state) do
    hd state.stacks
  end

  def update_stack(state, new_stack) do
    [_ | other_stacks] = state.stacks
    Map.put(state, :stacks, [new_stack | other_stacks])
  end

  def create_new_stack(state) do
    Map.put(state, :stacks, [[] | state.stacks])
  end

  def newest_stack_to_quotation(state) do
    [newest, next | rest] = state.stacks
    quot = Jux.Quotation.from_list(newest)
    updated_next = [quot | next]
    Map.put(state, :stacks, [updated_next | rest])
  end

  def get_iq(state) do
    hd state.instruction_queues
  end

  def update_iq(state, new_iq) do
    [_ | other_iqs] = state.instruction_queues
    Map.put(state, :instruction_queues, [new_iq | other_iqs])
  end

  def create_new_iq(state) do
    Map.put(state, :instruction_queues, [Okasaki.Queue.empty() | state.instruction_queues])
  end

  def drop_newest_iq(state) do
    Map.put(state, :instruction_queues, tl state.instruction_queues)
  end

  defp add_primitive(dictionary, name, function, compile_time_function \\ nil) do
    compile_time_function =
    if compile_time_function == nil do
      ref = Jux.Dictionary.definition_count(dictionary)
      fn state -> Primitive.push(state, {name, ref}) end
    else
      compile_time_function
    end
    dictionary
    |> Jux.Dictionary.define_new_word([function], [compile_time_function])
    |> Jux.Dictionary.rename_last_word(name)
  end

  # defp add_complex(dictionary, name, implementation) do
  #   compiled_implementation =
  #     implementation
  #     |> Enum.map(fn name -> get_reference!(dictionary, name) end)

  #   dictionary
  #   |> Jux.Dictionary.define_new_word(compiled_implementation)
  #   |> Jux.Dictionary.rename_last_word(name)
  # end

  def call(state = %__MODULE__{}) do
    case next_word(state) do
      :done ->
        IO.puts "Execution finished"
        state
      {word, state} ->
        call_word(word, state)
        |> call
    end
  end

  defp call_word(word, state) when is_function(word) do
    word.(state)
  end
  defp call_word(word, state) when is_integer(word) do
    {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word, mode(state))
    state
    |> add_impl_to_instruction_queue(impl)
  end

  def add_impl_to_instruction_queue(state, impl) do
    new_queue = Enum.into(get_iq(state), Okasaki.Queue.new(impl))
    state
    |> update_iq(new_queue)
  end

  @doc """
  Fetches the next word, by taking it from the instruction queue,
  or, if the instruction queue is empty, from the unparsed program directly.
  """
  def next_word(state)

  def next_word(state = %__MODULE__{instruction_queues: iqs = [current_iq | _], unparsed_program: ""}) do
    if !Okasaki.Queue.empty?(current_iq) do
      do_next_word(state)
    else
      :done
    end
  end

  def next_word(state = %__MODULE__{instruction_queues: iqs = [current_iq | _], unparsed_program: unparsed_program}) do
      if !Okasaki.Queue.empty?(current_iq) do
        do_next_word(state)
      else
        {token, rest} = Jux.Parser.extract_token(unparsed_program)
        compiled_token = Jux.Compiler.compile_token(token, state.dictionary, mode(state))

        new_state =
          state
          |> Map.put(:unparsed_program, rest)
        {compiled_token, new_state}
      end
  end

  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:ok, {word, new_instruction_queue}} = Okasaki.Queue.remove(get_iq(state))
    new_state = update_iq(state, new_instruction_queue)
    {word, new_state}
  end
end
