defmodule JuxTest do
  use ExUnit.Case
  doctest Jux

  test "the truth" do
    assert 1 + 1 == 2
  end

  # Jux.run_without_prelude("1 2 3 [ [ ] swap dip pop ] [ 42 ] define_new_word heave_token foo dump_stack rename_last_word dump_stack [ foo ] dump_stack dip dump_stack")
end
