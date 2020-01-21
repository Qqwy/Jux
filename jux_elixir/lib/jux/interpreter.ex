defmodule Jux.Interpreter do
  alias Jux.{State, Helper}
  alias __MODULE__.{Primitives, Dictionary, Integer, Quotation}

  def main(state \\ %State{}, input) do
    case Helper.take_first_word(input) do
      {:error, :empty} ->
        IO.puts("DONE")
        state
      {:ok, {"[", rest_input}} ->
        with {:ok, {quotation, rest_input2}} <- Helper.take_quotation(rest_input) do
          update_in(state.function_stack, fn stack -> [{:quotation, quotation} | stack] end)
          |> run_function_stack()
          |> main(rest_input2)
        end
      {:ok, {token, rest_input}} ->
        state
        |> add_token_to_function_stack(token)
        |> run_function_stack()
        |> main(rest_input)
    end
  end

  # TODO reading in quotations
  def add_token_to_function_stack(state, token) do
    case parse_token(state, token) do
      {:ok, token} ->
        update_in state.function_stack, fn stack -> [token | stack] end
      {:error, problem} ->
        raise problem
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
    case run_token(state, token) |> IO.inspect() do
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

  def run_token(state, {:quotation, quot}) do
    Quotation.run(state, quot)
  end
end
