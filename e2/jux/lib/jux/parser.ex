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
      state.instruction_queue
      |> EQueue.join(EQueue.from_list(token_implementation(state.dictionary, word)))

    # new_instruction_queue =
    #   state.instruction_queue
    #   |> EQueue.push(word)
    # IO.inspect(new_instruction_queue)

    state
    |> Map.put(:instruction_queue, new_instruction_queue)
    |> Map.put(:unparsed_program, unparsed_program_rest)
  end

  # Returns a list containin the implementation of the given word.
  # This is a single element, except for literals, which might contain multiple.
  defp token_implementation(dictionary, word) do
    case Jux.Dictionary.get_reference(dictionary, word) do
      {:ok, ref} ->
        [ref]
      _ ->
        case Integer.parse(word) do
          {int, ""} ->
            [
              Jux.Dictionary.get_reference!(dictionary, "lit_int"),
              int
            ]
          _ ->
            raise "Error: Unknown word found: #{word}"
        end
    end
  end

  # TODO superfluous?
  defp push_lit_int(state, int) do
    state.instruction_queue
    |> EQueue.push(Jux.Dictionary.get_reference!(state.dictionary, "lit_int"))
    |> EQueue.push(int)
  end


  # Should be called after matching the starting `[` as word,
  # so `unparsed_program` should be a binary like "1 2 3 ]".
  def build_quotation(unparsed_program, dictionary) do
    unparsed_program
    |> extract_token
    |> build_quotation(dictionary, Jux.Quotation.new)
  end

  # End of quotation reached
  defp build_quotation(["]", unparsed_program], _dictionary, acc = %Jux.Quotation{}) do
    {acc, unparsed_program}
  end

  # Start of nested quotation reached;
  # parse this quotation recursively
  # then continue on with outer quotation.
  defp build_quotation(["[", unparsed_program], dictionary, acc = %Jux.Quotation{}) do
    {inner_quot, unparsed_program_rest} = build_quotation(unparsed_program, dictionary)

    unparsed_program_rest
    |> extract_token
    |> build_quotation(dictionary, acc |> Jux.Quotation.push(inner_quot))
  end

  # recursive case; append compiled word, continue on.
  defp build_quotation([word, unparsed_program], dictionary, acc = %Jux.Quotation{}) do
    unparsed_program
    |> extract_token
    |> build_quotation(dictionary, acc |> Jux.Quotation.append(token_implementation(dictionary, word)))
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
