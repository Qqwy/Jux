defmodule Jux.Compiler do

  @doc """
  Returns a list of the token's implementation.
  """
  def compile_token(token, dictionary) do
    case {Integer.parse(token), token, Jux.Dictionary.get_reference(dictionary, token)} do
      {{int, ""}, _,      _} -> push_lit(int)
      {_, word = %Jux.Quotation{}, _} -> word
      {_, _,     {:ok, ref}} -> [ref]
      _                      -> raise "Error: Unknown token encountered: #{token}"
    end


    # case Integer.parse(word) do
    #   {int, ""} ->
    #     push_lit(int)
    #   _ ->
    #     case word do
    #       quotation = %Jux.Quotation{} ->
    #         push_lit(quotation)
    #       _ ->
    #         case Jux.Dictionary.get_reference(dictionary, word) do
    #           {:ok, ref} ->
    #             [ref]
    #           _ ->
    #             raise "Error: Unknown word found: #{word}"
    #         end
    #     end
    # end
  end


  defp push_lit(lit) do
    [fn state ->
      state
      |> Map.put(:stack, [lit | state.stack])
    end]
  end
end
