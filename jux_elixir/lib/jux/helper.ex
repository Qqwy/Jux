defmodule Jux.Helper do
  def declawed_string_to_atom(str) do
    try do
      {:ok, String.to_existing_atom(str)}
    rescue
      ArgumentError ->
        {:error, :unexistent_atom}
    end
  end

  def take_first_word(str) do
    str
    |> String.trim_leading
    |> take_first_word("")
  end

  def take_first_word("", accum) do
    case accum do
      "" -> {:error, :empty}
      other -> {:ok, {accum, ""}}
    end
  end
  def take_first_word(str = <<x::utf8, xs::binary>>, accum) when x == ?\s, do: {:ok, {accum, str}}
  def take_first_word(<<x::utf8, xs::binary>>, accum), do: take_first_word(xs, accum <> <<x>>)

  def take_quotation(str, accum \\ [])

  def take_quotation(str, accum) do
    case take_first_word(str) do
      {:error, problem} -> {:error, problem}
      {:ok, {"]", words}} ->
        {:ok, {:lists.reverse(accum), words}}
      {:ok, {"[", words}} ->
        case take_quotation(words) do
          {:error, problem} ->
            {:error, problem}
          {:ok, {inner_quotation, rest_words}} ->
            take_quotation(rest_words, [inner_quotation | accum])
        end
      {:ok, {word, words}} ->
        take_quotation(words, [word | accum])
    end
  end
end
