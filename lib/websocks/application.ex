defmodule Websocks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Websocks.PoolSupervisor, []},
      {Websocks.PoolHandler, %{}},
      {DynamicSupervisor, strategy: :one_for_one, name: Websocks.SocketSupervisor},
      %{
        id: Websocks.Acceptor,
        start: {Websocks.Acceptor, :start_link, [9999, {".certs/cert.pem", ".certs/key.pem", 'pass'}]}
      }
      # {Websocks.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Websocks.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
