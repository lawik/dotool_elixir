defmodule Dotool do
  @moduledoc """
  Documentation for `Dotool`.
  """

  File.mkdir_p!("_build")
  File.mkdir_p!("priv")
  @version "1.2"
  {_, 0} =
    System.shell(
      "curl -XGET https://git.sr.ht/~geb/dotool/archive/#{@version}.tar.gz > _build/dotool.tar.gz"
    )

  {_, 0} = System.shell("tar -C _build -xvzf _build/dotool.tar.gz")

  {_, 0} =
    System.shell(
      "cd _build/dotool-#{@version} && go build -ldflags \"-X main.Version=$DOTOOL_VERSION\""
    )

  @base_binary Path.join(:code.priv_dir(:dotool), "dotool")
  @client_binary Path.join(:code.priv_dir(:dotool), "dotoolc")
  @server_binary Path.join(:code.priv_dir(:dotool), "dotoold")
  File.cp!("_build/dotool-#{@version}/dotool", @base_binary)
  File.cp!("_build/dotool-#{@version}/dotoolc", @client_binary)
  File.cp!("_build/dotool-#{@version}/dotoold", @server_binary)

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(Dotool, opts, name: Dotool)
  end

  def init(opts) do
    state = %{
      port: Port.open({:spawn_executable, @base_binary}, [:binary, :stream])
    }

    {:ok, state}
  end

  def cmd(string) do
    GenServer.call(Dotool, {:do, string})
  end

  def handle_call({:do, cmd}, _from, state) do
    Port.command(state.port, "#{cmd}\n")
    {:reply, :ok, state}
  end

  def handle_info({_port, {:data, result}}, state) do
    Logger.warn("Unexpected output: #{result}")
    {:noreply, state}
  end
end
