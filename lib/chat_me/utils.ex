defmodule ChatMe.Utils do
  def get_username_list do
    Registry.lookup(UsernameRegistry, "username") |> Enum.map(&elem(&1, 1))
  end
end
