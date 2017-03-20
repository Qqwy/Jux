defmodule Jux.Parser do
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
