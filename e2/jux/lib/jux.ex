defmodule Jux do

  @doc """
  Runs the Jux program given as string `program`.
  """
  def run(program) do
    # program
    # |> String.trim_leading
    # |> Jux.State.new
    # |> Jux.Parser.parse_token
    # |> Jux.State.call
    quotation = 
      program
      |> Jux.Parser2.parse_source
 
    Jux.State.new([quotation])
    |> Jux.Builtin.execute_quotation
    |> Jux.State.call
  end
end
