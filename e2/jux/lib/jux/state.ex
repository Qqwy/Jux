defmodule Jux.State do
  @moduledoc """
  The complete state of the runtime system:

  - dictionary
  - parameter stack (not yet called functions)
  - return stack (calculated results)
  - mode
  """
  defstruct dictionary: Jux.Dictionary.new, stack: [], instruction_queue: EQueue.new, unparsed_program: ""

  def new(program, stack \\ []) when is_binary(program) do
    %__MODULE__{unparsed_program: program, stack: stack}
  end

  def call(state = %__MODULE__{}) do
    case next_word(state) do
      :done ->
        IO.puts "Execution finished"
      {word, state} ->
        IO.inspect({word, state})
        impl = Jux.Dictionary.get_implementation(state.dictionary, word)
        # state = %__MODULE__{state | instruction_queue: words}
        state =
          case impl do
            _ when is_function(impl) -> impl.(state)
            _ -> add_impl_to_instruction_queue(state, impl)
          end
        # Tail recursion == direct threading.
        # IO.inspect(state.stack)
        call(state)
        # raise "Unknown Word #{name}"
    end
  end

  # def call(state = %__MODULE__{instruction_queue: []}) do
  #   IO.puts "ok!"
  #   state
  # end


  def add_impl_to_instruction_queue(state, impl) do
    # TODO: Implementation expansion.
    IO.inspect(impl ++ state.instruction_queue)
    %__MODULE__{state | instruction_queue: impl ++ state.instruction_queue}
  end


  def run(program) do
    new(program)
    |> parse_word
    |> call
  end

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}, unparsed_program: ""}) do
    IO.puts "Execution finished!"
    IO.inspect(state.stack)
    :done
  end

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}}) do
    state
    |> parse_word
    |> do_next_word
  end


  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:value, word, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    {word, Map.put(state, :instruction_queue, new_instruction_queue)}
  end



  def parse_word(state = %__MODULE__{}) do
    [word, unparsed_program_rest] = extract_word(state.unparsed_program)
    new_instruction_queue =
      state.instruction_queue
      |> EQueue.push(word)
    IO.inspect(new_instruction_queue)

    state
    |> Map.put(:instruction_queue, new_instruction_queue)
    |> Map.put(:unparsed_program, unparsed_program_rest)
  end

  def extract_word(unparsed_program) do
      unparsed_program
      |> String.trim_leading
      |> String.split(~r{\b},parts: 2)
      |> IO.inspect
  end
end
