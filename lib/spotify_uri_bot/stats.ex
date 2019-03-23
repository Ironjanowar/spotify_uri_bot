defmodule SpotifyUriBot.Stats do
  use GenServer

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_user(uid) do
    GenServer.cast(__MODULE__, {:add_user, uid})
  end

  def add_group(cid) do
    GenServer.cast(__MODULE__, {:add_group, cid})
  end

  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_user, uid}, state) do
    Redix.command(:redix, ["SADD", "users", uid])
    {:noreply, state}
  end

  def handle_cast({:add_group, cid}, state) do
    Redix.command(:redix, ["SADD", "groups", cid])
    {:noreply, state}
  end

  def handle_call(:get_stats, _from, state) do
    {:ok, users} = Redix.command(:redix, ["SMEMBERS", "users"])
    {:ok, groups} = Redix.command(:redix, ["SMEMBERS", "groups"])

    {:reply, %{users: users, groups: groups}, state}
  end
end
