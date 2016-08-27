defmodule Jux.Parser do
  @moduledoc """
  Parses a string into a list of Jux tokens that can then be applied to a stack.
  """

  @whitespace_regexp ~r{\A\s+}m
  @comment_regexp ~r{^#.*}
  @float_regexp ~r{^[+-]?\d+\.\d+}
  @integer_regexp ~r{^[+-]?\d+}
  @identifier_regexp ~r{^[a-zA-Z_][\w.]*[?!]?}

  def valid_identifier?(str) do
    str =~ @identifier_regexp
  end

  @doc """
  Takes a string as input, returns a list of Jux tokens as output.
  Notice that the output of the parser is not yet reversed. 
  Before evaluation, this should happen; the tail of the list of tokens
  should be evaluated before the head.
  """
  def parse(str) do
    do_parse(str, [])
  end

  defp do_parse("", tokens), do: tokens
  defp do_parse(source, tokens) do
    #IO.inspect {source, tokens}
    cond do
      source =~ @whitespace_regexp ->
        [_, rest] = remove_token_from_string(source, @whitespace_regexp)
        do_parse(rest, tokens)
      source =~ @comment_regexp ->
        [_, rest] = remove_token_from_string(source, @comment_regexp)
        do_parse(rest, tokens)
      String.starts_with?(source, "[") ->
        [quotation, rest] = parse_quotation(source)
        do_parse(rest, [quotation | tokens])
      String.starts_with?(source, "\"") ->
        [string, rest] = parse_string(source)
        do_parse(rest, [string | tokens])
      source =~ @identifier_regexp ->
        [identifier, rest] = remove_token_from_string(source, @identifier_regexp)
        do_parse(rest, [parse_identifier(identifier) | tokens])
      source =~ @float_regexp ->
        [float, rest] = remove_token_from_string(source, @float_regexp)
        do_parse(rest, [parse_float(float) | tokens])
      source =~ @integer_regexp ->
        [integer, rest] = remove_token_from_string(source, @integer_regexp)
        do_parse(rest, [parse_integer(integer) | tokens])
      :otherwise ->
        raise "Could not parse rest of source: #{inspect source}"
    end
  end

  defp remove_token_from_string(source, regex) do 
    [prefix | _] = Regex.run(regex, source)
    #IO.inspect(prefix)
    #IO.inspect(String.replace_prefix(source, prefix, ""))
    [prefix, String.replace_prefix(source, prefix, "")]
  end


  def parse_quotation(source) do
    [quotation_length, rest] = do_parse_quotation(String.next_codepoint(source), 0, 0)
    quotation = String.slice(source, 1, quotation_length - 2)
    [parse(quotation), rest]
  end

  defp do_parse_quotation(nil, _, _) do
    raise "unmatched `[` in input."
  end

  defp do_parse_quotation({"[", rest}, bracket_count, length_acc) do
    # IO.puts "Position: #{length_acc}"
    do_parse_quotation(String.next_codepoint(rest), bracket_count+1, length_acc+1)
  end

  defp do_parse_quotation({"]", rest}, 1, length_acc) do
    [length_acc+1, rest]
  end

  defp do_parse_quotation({"]", rest}, bracket_count, length_acc) do
    do_parse_quotation(String.next_codepoint(rest), bracket_count-1, length_acc+1)
  end

  defp do_parse_quotation({_, rest}, bracket_count, length_acc) do
    do_parse_quotation(String.next_codepoint(rest), bracket_count, length_acc+1)
  end


  def parse_string(source) do
    [string_length, rest] = do_parse_string(String.next_codepoint(source), 0)
    string = String.slice(source, 1, string_length - 2)
    [string, rest]
  end

  defp do_parse_string({"\"", rest}, 0) do
    do_parse_string(String.next_codepoint(rest), 1)
  end

  defp do_parse_string({"\"", rest}, length) do
    [length+1, rest]
  end

  defp do_parse_string({"\\", rest}, length) do
    case String.next_codepoint(rest) do
      {"\"", restrest} ->
        do_parse_string(String.next_codepoint(restrest), length+2)
      {chars, _} ->
        do_parse_string(String.next_codepoint(rest), length+1)
    end
  end

  defp do_parse_string({_, rest}, length) do
    do_parse_string(String.next_codepoint(rest), length+1)
  end


  def parse_identifier(str) do
    # atom = str |> String.to_existing_atom
    # res = Jux.Stdlib.__info__(:functions)[atom]
    # if res != 1 do
    #   raise ArgumentError, "unknown identifier `#{str}`"
    # end
    # atom
    Jux.Identifier.new(str)
    #apply(Jux.Stdlib, atom, [stack])
  end

  def parse_integer(str) do
      str
      |> String.to_integer
  end

  def parse_float(str) do
      str
      |> String.to_float
  end

end
