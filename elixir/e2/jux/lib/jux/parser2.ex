defmodule Jux.Parser do

  def parse_source(source_code) do
    {quotation, ""} = 
      source_code
      |> String.trim_leading
      |> Kernel.<>(" ]")
      # |> IO.inspect
      |> parse_quotation
    quotation
  end

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
  """
  def extract_token(source) do
    case do_extract_token(source) do
      [word] -> {word, ""}
      [word, rest] -> {word, rest}
    end
  end

  defp do_extract_token(source) do
    source
    # |> String.trim_leading
    |> String.split(~r{\s},parts: 2)
    |> Enum.map(&String.trim_leading/1)
    # |> IO.inspect
  end
end
