defmodule BeepBop.Example.CardPayment do
  use Ecto.Schema

  schema("card_payment") do
    field(:status, :string, default: "pending")
  end
end

defmodule BeepBop.Example.CardPaymentMachine do
  use BeepBop, ecto_repo: BeepBop.TestRepo

  alias BeepBop.Example.CardPayment

  def persist(_, _), do: :ok

  state_machine(CardPayment, :status, ~w[pending authorized captured refunded voided failed]a) do
    event(:authorize, %{from: [:pending], to: :authorized}, fn c ->
      {:ok, c}
    end)
  end

  def __persistor_check__ do
    __beepbop_persist(:foo, :bar)
  end
end

defmodule BeepBop.Example.CardPaymentMachine.WithoutPersist do
  use BeepBop, ecto_repo: BeepBop.TestRepo

  alias BeepBop.Example.CardPayment, as: CP

  state_machine(CP, :status, ~w[pending cancelled]a) do
    event(:cancel, %{from: [:pending], to: :cancelled}, fn c ->
      {:ok, c}
    end)
  end

  def __persistor_check__ do
    __beepbop_persist(%CP{}, :bar)
  end
end