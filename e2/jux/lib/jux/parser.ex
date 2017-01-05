defmodule Jux.Parser do


  @doc """
  Parses the next word in the unparsed program and adds it to the state's instruction_queue:
  - either it is found in the dictionary, in which case its dictionary pointer is pushed.
  - or it is a literal integer, which is appended as the combined ["lit_int", integer_value] to the instruction queue.
  TODO handle quotations.
  """
  def parse_token(state = %Jux.State{}) do
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
    |> String.split(~r{\s},parts: 2)
    # |> IO.inspect
  end

end
