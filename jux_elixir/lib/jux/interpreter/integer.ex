defmodule Jux.Interpreter.Integer do
  def try_parse_run(state, token) do
    with {:ok, integer} <- try_parse(state, token) do
      run(state, integer)
    end
  end

  def try_parse(_state, token) do
    case Integer.parse(token) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :not_an_integer}
    end
  end

  def run(state, int) when is_integer(int) do
    new_state = update_in(state.stack, fn stack -> [int | stack] end)
    {:ok, new_state}
  end
end
