defmodule Websocks.Acceptor do
  alias Websocks.Socket
def start_link(port, {certfile,keyfile,password}) do
  :ssl.start()
  {:ok, listenSocket} =
    :ssl.listen(port,
      certfile: certfile,
      keyfile: keyfile,
      reuseaddr: true,
      password: password
    )
    loop(listenSocket)
end

def loop(listenSocket) do
  {:ok, tlsSocket} = :ssl.transport_accept(listenSocket)
  {:ok,pid} = DynamicSupervisor.start_child(Websocks.SocketSupervisor,{Websocks.Socket,tlsSocket})
  :ssl.controlling_process(tlsSocket,pid)
  Socket.upgrade_connection(pid,tlsSocket)
  Socket.send(pid,"Hello World! :)")
  loop(listenSocket)
end


end
