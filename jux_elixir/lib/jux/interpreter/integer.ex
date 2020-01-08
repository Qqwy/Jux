defmodule Jux.Interpreter.Integer do
  def try_parse_run(state, token) do
    with {:ok, integer} <- try_parse(token) do
      new_state = update_in(state.stack, fn stack -> [integer|stack] end)
      {:ok, new_state}
    end
  end

  def try_parse(token) do
    case Integer.parse(token) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :not_an_integer}
    end
  end
end
