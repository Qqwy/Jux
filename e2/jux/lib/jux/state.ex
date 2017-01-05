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
        IO.inspect(state.stack)
      {word, state} ->
        # IO.inspect({word, state})
        {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word)
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
    |> parse_token
    |> call
  end

  @doc """
  Fetches the next word, by taking it from the instruction queue,
  or, if the instruction queue is empty, from the unparsed program directly.
  """
  def next_word(state)

  def next_word(_state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}, unparsed_program: ""}) do
    # IO.puts "Execution finished!"
    :done
  end

  def next_word(state = %__MODULE__{instruction_queue: %EQueue{data: {[],[]}}}) do
    state
    |> parse_token
    |> do_next_word
  end


  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:value, word, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    {word, Map.put(state, :instruction_queue, new_instruction_queue)}
  end

  @doc """
  Parses the next word in the unparsed program and adds it to the state's instruction_queue:
  - either it is found in the dictionary, in which case its dictionary pointer is pushed.
  - or it is a literal integer, which is appended as the combined ["lit_int", integer_value] to the instruction queue.
  TODO handle quotations.
  """
  def parse_token(state = %__MODULE__{}) do
    [word, unparsed_program_rest] = extract_token(state.unparsed_program)


    new_instruction_queue =
      case Jux.Dictionary.get_reference(state.dictionary, word) do
        {:ok, ref} ->
          state.instruction_queue
          |> EQueue.push(ref)
        _ ->
          case Integer.parse(word) do
            {int, ""} ->
              state.instruction_queue
              |> EQueue.push(Jux.Dictionary.get_reference!(state.dictionary, "lit_int"))
              |> EQueue.push(int)
            _ ->
              raise "Error: Unknown word found: #{word}"
          end
      end

    # new_instruction_queue =
    #   state.instruction_queue
    #   |> EQueue.push(word)
    # IO.inspect(new_instruction_queue)

    state
    |> Map.put(:instruction_queue, new_instruction_queue)
    |> Map.put(:unparsed_program, unparsed_program_rest)
  end

  @doc """
  Extracts the next token from the given unparsed program.
  """
  def extract_token(unparsed_program) do
      unparsed_program
      |> String.trim_leading
      |> String.split(~r{\b},parts: 2)
      # |> IO.inspect
  end
end
