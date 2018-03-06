defmodule ChatMe.TCPServer do
  require Logger
  use GenServer

  def start_link(port \\ 4444) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    Logger.info("Starting server on port #{port}")
    send(self(), :start_accepting)
    :gen_tcp.listen(port, [:binary, packet: :line, active: :once, reuseaddr: true])
  end

  def handle_info(:start_accepting, socket) do
    Logger.info("Accepting connections")
    GenServer.start(ChatMe.Connection, socket) |> IO.inspect(label: "starting child")
    send(self(), :start_accepting)
    {:noreply, socket}
  end
end
