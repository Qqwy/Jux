defmodule Jux.State do

  @moduledoc """
  The complete state of the runtime system:

  - dictionary
  - parameter stack (not yet called functions)
  - return stack (calculated results)
  - mode
  """
  defstruct dictionary: setup_dictionary, stack: [], instruction_queue: EQueue.new, unparsed_program: ""

  def new(source, stack \\ []) do
    %__MODULE__{unparsed_program: source, stack: stack}
  end


  def setup_dictionary do
    %Jux.Dictionary{}
    |> add_primitive("puts", &Primitive.puts/1)
    |> add_primitive("dup", &Primitive.dup/1)
    |> add_primitive("pop", &Primitive.pop/1)
    |> add_primitive("swap", &Primitive.swap/1)
    |> add_primitive("dnw", &Primitive.define_new_word/1)
    |> add_primitive("rlw", &Primitive.rename_last_word/1)

  end

  defp add_primitive(dictionary, name, function) do
    dictionary
    |> Jux.Dictionary.define_new_word([function])
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
      {word, state} ->
        if is_function(word) do
          word.(state)
          |> call
        else
          {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word)
          call_impl(state, impl)
          |> call # Tail recurse
        end
    end
  end

  defp call_impl(state = %__MODULE__{}, impl) do
      case impl do
        _ when is_function(impl) ->
          impl.(state)
        _ ->
          add_impl_to_instruction_queue(state, impl)
      end
  end

  def add_impl_to_instruction_queue(state, impl) do
    # TODO: Implementation expansion.
    new_queue = EQueue.join(EQueue.from_list(impl), state.instruction_queue)
    %__MODULE__{state | instruction_queue: new_queue}
  end

  @doc """
  Fetches the next word, by taking it from the instruction queue,
  or, if the instruction queue is empty, from the unparsed program directly.
  """
  def next_word(state)

  def next_word(_state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}, unparsed_program: ""}) do
    :done
  end

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}}) do
    state
    |> Jux.Parser.parse_token
    |> do_next_word
  end

  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:value, word, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    {word, Map.put(state, :instruction_queue, new_instruction_queue)}
  end



end
