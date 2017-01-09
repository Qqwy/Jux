defmodule Jux.State do
  @moduledoc """
  The complete state of the runtime system:

  - dictionary
  - parameter stack (not yet called functions)
  - return stack (calculated results)
  - mode
  """
  defstruct dictionary: Jux.Dictionary.new, stack: [], instruction_queue: EQueue.new, unparsed_program: ""

  # def new(program, stack \\ []) when is_binary(program) do
  #   %__MODULE__{unparsed_program: program, stack: stack}
  # end
  # def new(queue, stack \\ []) do
  #   %__MODULE__{instruction_queue: queue, stack: stack}
  # end
  def new(stack \\ []) do
    %__MODULE__{stack: stack}
  end

  def call(state = %__MODULE__{}) do
    # IO.inspect(state)
    case next_word(state) do
      :done ->
        IO.puts "Execution finished"
        # IO.inspect(state.stack)
      {word, state} ->
        if is_function(word) do
          word.(state)
          |> call
        else
          {:ok, impl} = Jux.Dictionary.get_implementation(state.dictionary, word)
          call_impl(state, impl)
          # |> IO.inspect
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
    # IO.inspect(impl ++ state.instruction_queue)
    new_queue = EQueue.join(EQueue.from_list(impl), state.instruction_queue)
    # IO.inspect new_queue
    %__MODULE__{state | instruction_queue: new_queue}
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
    |> Jux.Parser.parse_token
    |> do_next_word
  end


  def next_word(state = %__MODULE__{}), do: do_next_word(state)

  def do_next_word(state = %__MODULE__{}) do
    {:value, word, new_instruction_queue} = state.instruction_queue |> EQueue.pop
    {word, Map.put(state, :instruction_queue, new_instruction_queue)}
  end


end
