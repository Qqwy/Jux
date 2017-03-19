defmodule Jux.Parser do
  @doc """
  Attempts to parse the given source as a quotation.
  This means it _has_ to start with " [ " and end with " ] "
  otherwise, it raises.
  """
  def parse_quotation(source) do
    source
    |> extract_token
    # |> IO.inspect
    |> parse_quotation(Jux.Quotation.new)
  end

  defp parse_quotation({"]", source}, acc) do
    # IO.puts "END OF QUOTATION"
    {acc, source}
  end

  defp parse_quotation({"[", source}, acc) do
    {inner_quotation, source_rest} = parse_quotation(source)
    source_rest
    |> extract_token
    # |> IO.inspect
    |> parse_quotation(acc |> Jux.Quotation.push(inner_quotation))
  end

  defp parse_quotation({_, ""}, acc) do
    raise "Error: Encountered EOF while parsing #{inspect(acc)}"
  end

  defp parse_quotation({token, source}, acc) do
    source
    |> extract_token
    # |> IO.inspect
    |> parse_quotation(acc |> Jux.Quotation.push(token))
  end

  @doc """
  Extracts the next token from the given unparsed program.
  In core Jux, tokens are álways separated by one or more \s.
  """
  def extract_token(source) do
    case do_extract_token(source) do
      [word]       -> {String.trim(word), ""}
      [word, rest] -> {String.trim(word), rest}
    end
  end

  defp do_extract_token(source) do
    source
    |> String.split(~r{\s*\b|\s+},parts: 2)
    |> Enum.map(&String.trim_leading/1)
  end
end
