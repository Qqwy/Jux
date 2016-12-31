defmodule Jux.Dictionary do
  defstruct [
    definition_count: 0,
    definitions: %{}, # definition reference -> implementation of function definitions.
    names: %{}        # name -> list of definition references.
  ]


  defmodule Builtin do

    def dup(state) do
      [n | stack] = state.stack
      Map.put(state, :stack, [n, n | stack])
    end

    def pop(state) do
      [_ | stack] = state.stack
      Map.put(state, :stack, stack)
    end

    def swap(state) do
      [a, b | rest] = state.stack
      Map.put(state, :stack, [b, a | rest])
    end

    def puts(state) do
      [n | stack ] = state.stack
      IO.puts(n)
      Map.put(state, :stack, stack)
    end

    def lit_int(state) do
      [word, new_unparsed_program] = Jux.State.extract_word(state.unparsed_program)
      word_int = word |> String.to_integer
      # IO.inspect({:unparsed_program, new_unparsed_program})

      state
      |> Map.put(:unparsed_program, new_unparsed_program)
      |> Map.put(:stack, [word_int | state.stack])
    end
  end

  def new() do
    %__MODULE__{}
    |> add_word("puts", &Builtin.puts/1)
    |> add_word("dup", &Builtin.dup/1)
    |> add_word("pop", &Builtin.pop/1)
    |> add_word("swap", &Builtin.swap/1)
    |> add_word("lit_int", &Builtin.lit_int/1)
    |> add_word("test", ["puts", "swap", "dup"])
  end

  # TODO: Compile implementation.
  def add_word(dictionary, name, implementation) do
    reference = dictionary.definition_count
    new_definitions = Map.put(dictionary.definitions, reference, implementation)
    current_refs = dictionary.names[name] || []
    new_names = Map.put(dictionary.names, name, [reference | current_refs])
    %__MODULE__{dictionary | definition_count: reference + 1, definitions: new_definitions, names: new_names}
  end

  @doc """
  NOTE: Inherently unsafe.

  Better would be a method that forgets _everything_ up to and including
  this word.
  """
  def remove_word(dictionary, name) do
    [reference | prev_refs] = dictionary.names[name]
    definitions = Map.delete(dictionary.definitions, reference)
    names = Map.put(dictionary.names, name, prev_refs)
    %__MODULE__{dictionary | definitions: definitions, names: names}
  end

  def get_implementation(dictionary, name) do
    ref =
      dictionary
      |> get_reference(name)
    dictionary.definitions[ref]
  end

  def get_reference(dictionary, name) do
    dictionary.names[name] |> List.first
  end

end
