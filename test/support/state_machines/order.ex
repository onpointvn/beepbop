defmodule BeepBop.Example.OrderMachine do
  @moduledoc """
  ## Defined events
  * `:foobar`
    Has no "to_state", and the event callback has full freedom to set the
    `to_state`. In fact, there is no validation on the `to_state`.
  """
  use BeepBop, ecto_repo: BeepBop.TestRepo

  state_machine(
    BeepBop.Example.Order,
    :state,
    ~w[cart address payment shipping shipped cancelled]a
  ) do
    event(:foobar, %{from: [:cart]}, fn context ->
      s = struct(context.struct, state: :foo)
      context
    end)

    event(:set_address, %{from: [:cart], to: :address}, fn context ->
      s = struct(context.struct, state: :address)
      context
    end)

    event(:payment, %{from: [:address], to: :payment}, fn context ->
      s = struct(context.struct, state: :payment)
      context
    end)

    event(:add_more_item, %{from: [:address, :payment], to: :cart}, fn context ->
      s = struct(context.struct, state: :cart)
      context
    end)

    event(:will_fail, %{from: [:cart], to: :cancelled}, fn context ->
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:failure, fn _, _ ->
          {:error, :failed}
        end)

      struct(context, multi: multi)
    end)
  end
end
