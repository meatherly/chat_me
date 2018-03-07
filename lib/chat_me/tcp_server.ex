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
    Logger.info("Accepting connection")
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, connection} = DynamicSupervisor.start_child(ChatMe.ConnectionSupervisor, {ChatMe.Connection, client})
    :ok = :gen_tcp.controlling_process(client, connection)
    send(self(), :start_accepting)
    {:noreply, socket}
  end
end