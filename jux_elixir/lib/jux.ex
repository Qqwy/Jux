defmodule Jux do
  defmodule State do
    defstruct [stack: [],
               function_stack: [],
               dictionary: %{},
              ]
  end

  defmodule Primitives do
  end

  def read_token do
  end

  def main(state \\ %State{}, input) do
    case input |> String.trim_leading |> take_first_word do
      {:error, :empty} ->
        IO.puts("DONE")
        state
      {:ok, {token, rest_input}} ->
        state
        |> add_token_to_function_stack(token)
        |> run_function_stack()
        |> main(rest_input)
    end
  end

  def take_first_word(str), do: take_first_word(str, "")
  def take_first_word("", accum) do
    case accum do
      "" -> {:error, :empty}
      other -> {:ok, {accum, ""}}
    end
  end
  def take_first_word(str = <<x::utf8, xs::binary>>, accum) when x == ?\s, do: {:ok, {accum, str}}
  def take_first_word(<<x::utf8, xs::binary>>, accum), do: take_first_word(xs, accum <> <<x>>)


  def add_token_to_function_stack(state, token) do
    update_in state.function_stack, fn stack -> [token | stack] end
  end
  def run_function_stack(state) do
    case state.function_stack do
      [] -> state
      [x | xs] ->
        state
        |> Map.put(:function_stack, xs)
        |> run_function_stack_fn(x)
        |> run_function_stack()
    end
  end

  def run_function_stack_fn(state, token) do
    IO.puts("Running token #{token} on state #{inspect(state)}")
    state
  end
end
