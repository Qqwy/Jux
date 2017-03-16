defmodule Jux.Compiler do

  @doc """
  Returns a function that implement the token's behaviour.
  """
  # TODO Rewrite using `with`?
  def compile_token(word, dictionary) do
    case word do
      quotation = %Jux.Quotation{} ->
        push_lit(quotation)
      _ ->
        case Integer.parse(word) do
          {int, ""} ->
            push_lit(int)
          _ ->
            case Jux.Dictionary.get_reference(dictionary, word) do
              {:ok, ref} ->
                ref
              _ ->
                raise "Error: Unknown word found: #{word}"
            end
        end
    end
  end

  # Returns a closure that puts the given literal on the Jux.State's :stack field when executed.
  defp push_literal(lit) do
    fn state ->
      Map.put(state, :stack, [lit | state.stack])
    end
  end
end
