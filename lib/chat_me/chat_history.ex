defmodule ChatMe.History do
  use Agent
  require Logger

  def start_link(_opts) do
    Logger.info("Starting History Agent")
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def put_message(message) do
    Agent.update(__MODULE__, &[message | &1])
  end

  def get_messages(count) do
    Agent.get(__MODULE__, fn messages ->
      Enum.take(messages, count)
      |> Enum.reverse()
    end)
  end
end
