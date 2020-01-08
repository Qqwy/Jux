defmodule Jux.Interpreter.Quotation do
  def try_parse(state, token) do
  end

  def run(state, quot) do
    new_state = update_in(state.stack, fn stack -> [quot | stack] end)
    {:ok, new_state}
  end
end
