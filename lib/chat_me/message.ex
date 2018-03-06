defmodule ChatMe.Message do
  defstruct [:body, :mentions, :timestamp, :username]

  def encode(%__MODULE__{body: body, username: username, timestamp: timestamp}) do
    "[#{Time.truncate(timestamp, :second)}] <#{username}> #{body}\n"
  end

  def add_mentions(%__MODULE__{body: body} = message) do
    mentions =
      Regex.scan(~r/@([a-zA-Z0-9_-]{3,16})/, body, capture: :all_but_first) |> List.flatten()

    %{message | mentions: mentions}
  end
end
