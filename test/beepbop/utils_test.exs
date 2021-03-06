defmodule BeepBop.UtilsTest do
  use ExUnit.Case, async: true

  alias BeepBop.Utils

  @msg_missing_repo """
  Please configure an Ecto.Repo by passing an Ecto.Repo like so:
      use BeepBop, ecto_repo: YourProject.Repo
  """
  @msg_not_a_struct " does not define a struct"
  @msg_missing_column "doesn't have any column named:"
  @msg_not_loaded "could not be loaded"

  @msg_from_atom_list "bad 'from'/'not_from': should be a list of atoms, got: "
  @msg_from_empty "bad 'from': cannot be empty!"
  @msg_not_from_empty @msg_from_empty <> " Did you remove all using `:not_from`?"
  @msg_to_atom "bad 'to': expected atom, got: "

  @msg_bad_states "All states must be atoms, got: "
  @msg_events_unique "Event names must be unique."
  @msg_atleast_one_state "A State Machine must have atleast one state!"
  @msg_bad_transition_format "bad format of `options` in `event/3`, please refer the docs."

  @states ~w[foo bar baz]a

  @bad_transitions %{
    a: %{from: [:bar], to: :bar},
    b: %{from: @states, to: :void},
    c: %{from: [], to: :baz},
    d: %{from: [:void, :foo], to: :baz},
    e: %{from: [:void], to: :void}
  }

  @states_error ~s{    event 'e': bad 'from': [:void], bad 'to': :void
    event 'd': bad 'from': [:void]
    event 'c': #{@msg_not_from_empty}
    event 'b': bad 'to': :void}

  @good_transitions %{
    a: %{from: [:bar], to: :bar},
    b: %{from: @states, to: :baz},
    c: %{from: [:bar]}
  }

  test "extract_schema_name/1" do
    alias BeepBop.NotAModule, as: FooBar
    assert Utils.extract_schema_name(quote(do: FooBar), __ENV__) == :not_a_module
    assert Utils.extract_schema_name(quote(do: Foo), __ENV__) == :foo

    assert Utils.extract_schema_name(quote(do: BeepBop.Example.CardPayment), __ENV__) ==
             :card_payment
  end

  test "assert_repo!/1" do
    refute Utils.assert_repo!(ecto_repo: FooBar)
    assert_raise(RuntimeError, @msg_missing_repo, fn -> Utils.assert_repo!([]) end)
  end

  test "assert_schema!/1" do
    alias BeepBop.Example.CardPayment
    refute Utils.assert_schema!(CardPayment, :status)

    assert_raise(RuntimeError, "BeepBop.TestRepo" <> @msg_not_a_struct, fn ->
      Utils.assert_schema!(BeepBop.TestRepo, :foo)
    end)

    assert_raise(
      RuntimeError,
      "BeepBop.Example.CardPayment #{@msg_missing_column} :tricked",
      fn ->
        Utils.assert_schema!(CardPayment, :tricked)
      end
    )

    assert_raise(RuntimeError, "FooBar #{@msg_not_loaded}. Reason: :nofile", fn ->
      Utils.assert_schema!(FooBar, :foobar)
    end)
  end

  test "assert_num_states!/1" do
    assert_raise(RuntimeError, @msg_atleast_one_state, fn ->
      Utils.assert_num_states!([])
    end)

    refute Utils.assert_num_states!([:a])
  end

  test "assert_states!/1" do
    refute Utils.assert_states!(@states)

    assert_raise(RuntimeError, @msg_bad_states <> ":foo", fn ->
      Utils.assert_states!(:foo)
    end)

    assert_raise(RuntimeError, @msg_bad_states <> "[1]", fn ->
      Utils.assert_states!([1])
    end)
  end

  test "assert_unique_events!/1" do
    unique = [1, 2, 3]
    duplicates = [1, 2, 1]

    assert_raise(RuntimeError, @msg_events_unique, fn ->
      Utils.assert_unique_events!(duplicates)
    end)

    refute Utils.assert_unique_events!(unique)
  end

  test "assert_transition_opts!/1" do
    refute Utils.assert_transition_opts!(%{from: @states, to: :foo})
    refute Utils.assert_transition_opts!(%{from: :any, to: :foo})
    refute Utils.assert_transition_opts!(%{from: %{not: []}, to: :foo})
    refute Utils.assert_transition_opts!(%{from: %{not: @states}, to: :foo})

    assert_raise(RuntimeError, @msg_bad_transition_format, fn ->
      Utils.assert_transition_opts!(%{foo: :bar})
    end)

    assert_raise(RuntimeError, @msg_from_atom_list <> ":bar", fn ->
      Utils.assert_transition_opts!(%{from: :bar, to: :baz})
    end)

    assert_raise(RuntimeError, @msg_from_empty, fn ->
      Utils.assert_transition_opts!(%{from: [], to: :foo})
    end)

    assert_raise(RuntimeError, @msg_from_atom_list <> "[1, 2]", fn ->
      Utils.assert_transition_opts!(%{from: [1, 2], to: :foo})
    end)

    assert_raise(RuntimeError, @msg_from_atom_list <> "[1, 2]", fn ->
      Utils.assert_transition_opts!(%{from: %{not: [1, 2]}, to: :foo})
    end)

    assert_raise(RuntimeError, @msg_to_atom <> "[:foo]", fn ->
      Utils.assert_transition_opts!(%{from: @states, to: [:foo]})
    end)
  end

  test "assert_transitions!/2" do
    refute Utils.assert_transitions!(@states, @good_transitions)

    assert_raise(RuntimeError, @states_error, fn ->
      Utils.assert_transitions!(@states, @bad_transitions)
    end)
  end
end
