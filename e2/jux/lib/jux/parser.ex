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
              push_lit_int(state, int)
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

  defp push_lit_int(state, int) do
    state.instruction_queue
    |> EQueue.push(Jux.Dictionary.get_reference!(state.dictionary, "lit_int"))
    |> EQueue.push(int)
  end


  # Should be called after matching the starting `[` as word,
  # so `unparsed_program` should be a binary like "1 2 3 ]".
  def build_quotation(unparsed_program) do
    unparsed_program
    |> extract_token
    |> build_quotation(Jux.Quotation.new)
  end

  # End of quotation reached
  defp build_quotation(["]", unparsed_program], acc = %Jux.Quotation{}) do
    {acc, unparsed_program_rest}
  end

  # Start of nested quotation reached;
  # parse this quotation recursively
  # then continue on with outer quotation.
  defp build_quotation(["[", unparsed_program], acc = %Jux.Quotation{}) do
    {inner_quot, unparsed_program_rest} = build_quotation(unparsed_program)

    unparsed_program_rest
    |> extract_token
    |> build_quotation(acc |> Jux.Quotation.push(inner_quot))
  end

  # recursive case; append compiled word, continue on.
  defp build_quotation([word, unparsed_program], acc = %Jux.Quotation{}) do
    word_ref = Jux.Dictionary.get_reference!(word_ref)

    unparsed_program_rest
    |> extract_token
    |> build_quotation(acc |> Jux.Quotation.push(word_ref))
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
