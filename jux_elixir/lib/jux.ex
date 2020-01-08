defmodule Jux do
  defmodule State do
    defstruct [stack: [],
               function_stack: [],
               dictionary: %{},
              ]
  end

  defmodule Primitives do
    def dup(state) do
      update_in(state.stack, fn
        [] -> raise "Error, empty stack"
        [x|xs] -> [x,x|xs]
      end)
    end

    def swap(state) do
      update_in(state.stack, fn
        [] -> raise "Error, empty stack"
        [x] -> raise "Error, one element stack"
        [x,y|rest] -> [y,x|rest]
      end)
    end

    def pop(state) do
      update_in(state.stack, fn
        [] -> raise "Error, empty stack"
        [x|rest] -> rest
      end)
    end

    def add(state) do
      update_in(state.stack, fn
        [] -> raise "Error, empty stack"
        [x] -> raise "Error, one element stack"
        [x,y|rest] -> [x + y|rest]
      end)
    end

    def bnand(state) do
      use Bitwise
      update_in(state.stack, fn
        [] -> raise "Error, empty stack"
        [x] -> raise "Error, one element stack"
        [x,y|rest] -> [bnot(x &&& y)|rest]
      end)
    end
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

  # TODO reading in quotations
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
    case parse_run_token(state, token) do
      {:ok, state} -> state
      {:error, error} -> raise error
    end
    # case try_parse_integer(token) do
    #     {:ok, integer} ->
    #     update_in(state.stack, fn stack -> [integer|stack] end)
    #   {:error, _} ->
    #     IO.puts("Running token #{token} on state #{inspect(state)}")
    #     atom_token = String.to_existing_atom(token)
    #     apply(Primitives, atom_token, [state])
    # end
  end

  def parse_run_token(state, token) do
    with {:error, _} <- try_parse_run_integer(state, token),
         {:error, _} <- try_lookup_run_dictionary(state, token),
         {:error, _} <- try_lookup_run_primitive(state, token) do
      {:error,  "Could not parse/run token #{token}."}
    end
  end

  def try_parse_run_integer(state, token) do
    with {:ok, integer} <- try_parse_integer(token) do
      new_state = update_in(state.stack, fn stack -> [integer|stack] end)
      {:ok, new_state}
    end
  end

  def try_parse_integer(token) do
    case Integer.parse(token) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :not_an_integer}
    end
  end

  def try_lookup_run_dictionary(state, token) do
    {:error, :not_implemented}
  end

  def try_lookup_run_primitive(state, token) do
    with {:ok, atom} <- try_lookup_primitive(token) do
      new_state = apply(Primitives, atom, [state])
      {:ok, new_state}
    end
  end

  def try_lookup_primitive(token) do
    with {:ok, atom} <- declawed_string_to_atom(token),
         true <- function_exported?(Primitives, atom, 1) do
      {:ok, atom}
    else
      false ->
        {:error, :not_a_primitive}
      {:error, :unexistent_atom} ->
        {:error, :not_a_primitive}
    end
  end

  def declawed_string_to_atom(str) do
    try do
      {:ok, String.to_existing_atom(str)}
    rescue
      ArgumentError ->
        {:error, :unexistent_atom}
    end
  end
end
