defmodule Jux.Interpreter do
  alias Jux.State
  alias __MODULE__.{Primitives, Dictionary, Integer}

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

  # TODO reading in quotations
  def add_token_to_function_stack(state, token) do
    with {:ok, token} <- parse_token(state, token) do
      update_in state.function_stack, fn stack -> [token | stack] end
    end
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

  # TODO the parsing stuff ought to happen when a new token is added to the function stack instead.
  def run_function_stack_fn(state, token) do
    case run_token(state, token) do
      {:ok, state} -> state
      {:error, error} -> raise error
    end
  end

  def parse_token(state, token) do
    with {:error, _} <- Integer.try_parse(state, token),
         {:error, _} <- Dictionary.try_lookup(state, token),
         {:error, _} <- Primitives.try_lookup(state, token) do
      {:error,  "Could not parse/run token #{token}."}
    end
  end

  # def parse_run_token(state, token) do
  #   with {:error, _} <- Integer.try_parse_run(state, token),
  #        {:error, _} <- Dictionary.try_lookup_run(state, token),
  #        {:error, _} <- Primitives.try_lookup_run(state, token) do
  #     {:error,  "Could not parse/run token #{token}."}
  #   end
  # end
  def run_token(state, int) when is_integer(int) do
    Integer.run(state, int)
  end

  def run_token(state, list) when is_list(list) do
    Dictionary.run(state, list)
  end

  def run_token(state, atom) when is_atom(atom) do
    Primitives.run(state, atom)
  end
end
