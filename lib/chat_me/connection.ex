defmodule ChatMe.Connection do
  use GenServer
  require Logger
  alias ChatMe.{Message, Utils}

  defstruct client: nil, joined: false, username: nil

  def init(socket) do
    send(self(), :get_username)
    {:ok, client} = :gen_tcp.accept(socket)
    :gen_tcp.send(client, "Welcome to my chat server! What is your nickname?\n")
    :ok = :gen_tcp.controlling_process(client, self())
    {:ok, %__MODULE__{client: client}}
  end

  def handle_info({:tcp, _port, message}, %{joined: false, client: client} = state) do
    username = String.trim(message)
    Logger.info("Recieved username for join: #{username}")

    state =
      with {:ok, username} <- validate_username(username),
           {:ok, username} <- check_if_user_exists(username) do
        user_joined(username)
        send_join_info(client, Utils.get_username_list())
        Registry.register(UsernameRegistry, "username", username)
        :inet.setopts(client, active: true)
        Map.merge(state, %{joined: true, username: username})
      else
        {_, err_msg} ->
          :gen_tcp.send(client, err_msg)
          :inet.setopts(client, active: :once)
          state
      end

    {:noreply, state}
  end

  def handle_info({:tcp, _port, message}, %{joined: true} = state) do
    msg = String.trim(message)
    Logger.info("Recieved message: #{msg}")

    %Message{timestamp: Time.utc_now(), body: msg, username: state.username}
    |> Message.add_mentions()
    |> broadcast_msg

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, %{joined: true, username: username} = state) do
    Logger.info("Client disconnected")
    user_left(username)
    {:stop, :normal, state}
  end

  def handle_info(
        {:broadcast_msg, %{username: sender_username} = msg},
        %{username: username} = state
      )
      when sender_username != username do
    msg =
      if username in msg.mentions do
        put_in(msg.body, msg.body <> "\a")
      else
        msg
      end

    message = msg |> Message.encode()
    Logger.info("broadcasting message #{message}")
    :gen_tcp.send(state.client, message)
    {:noreply, state}
  end

  def handle_info({:user_left, msg}, state) do
    :gen_tcp.send(state.client, msg)
    {:noreply, state}
  end

  def handle_info({:user_joined, msg}, state) do
    Logger.info("Client connected")
    :gen_tcp.send(state.client, msg)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Didn't catch this message #{inspect(msg)}")
    {:noreply, state}
  end

  def validate_username(username) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]{3,16}$/, username) do
      {:ok, username}
    else
      {:bad_username,
       "Username must be 3 - 16 chars long. Only special chars allowed are: -, _\n"}
    end
  end

  def check_if_user_exists(username) do
    case Registry.match(UsernameRegistry, "username", :"$1", [{:==, :"$1", username}]) do
      [] ->
        {:ok, username}

      _ ->
        {:user_exists, "#{username} already exists. please choose another one.\n"}
    end
  end

  def user_joined(username) do
    {:user_joined, "*#{username} has joined the chat*\n"} |> broadcast
  end

  def user_left(username) do
    {:user_left, "*#{username} has left the chat*\n"} |> broadcast
  end

  def broadcast_msg(message) do
    ChatMe.History.put_message(message)
    {:broadcast_msg, message} |> broadcast
  end

  def broadcast(msg) do
    Registry.dispatch(UsernameRegistry, "username", fn users ->
      for {pid, _} <- users, do: send(pid, msg)
    end)
  end

  def send_join_info(client, other_users) do
    :gen_tcp.send(
      client,
      "You are connected with #{other_users |> length} other users: [#{
        other_users |> Enum.join(",")
      }]\n"
    )

    ChatMe.History.get_messages(10)
    |> Enum.each(fn message -> :gen_tcp.send(client, message |> Message.encode()) end)
  end
end
