defmodule Websocks do
  @moduledoc """
  Documentation for `Websocks`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Websocks.hello()
      :world

  """
  def hello do
    :world
  end

  def accept() do

    :ssl.start
    {:ok, listenSocket} = :ssl.listen(9999, [certfile: ".certs/cert.pem", keyfile: ".certs/key.pem", reuseaddr: true, password: 'pass'])
    {:ok, tlsSocket} = :ssl.transport_accept(listenSocket)
    {:ok, socket} = :ssl.handshake(tlsSocket)
    request = receive do
        {:ssl, {:sslsocket, {:gen_tcp, _port, :tls_connection, _},_}, request} -> request
    end


    parsed_request = String.split(to_string(request),"\r\n",[trim: true])
    |> Enum.filter(fn val ->
        String.starts_with?(val,["Host","Sec-WebSocket-Version","Sec-WebSocket-Extensions","Sec-WebSocket-Key","Upgrade"])
       end)
    |> Enum.map(fn val -> val |> String.split(": ",[trim: true, parts: 2]) |> List.to_tuple end)

    parameters = [
                  host: get_value_from_key(parsed_request,"Host"),
                  version: get_value_from_key(parsed_request,"Sec-WebSocket-Version"),
                  extensions: get_value_from_key(parsed_request,"Sec-WebSocket-Extensions"),
                  key: get_value_from_key(parsed_request,"Sec-WebSocket-Key"),
                  upgrade: get_value_from_key(parsed_request,"Upgrade")
                ]

    if parameters[:upgrade] != "websocket" do
      :ssl.close(socket)
    end
    response = parameters[:key]
    |> compute_key |> compute_response
    :ssl.send(socket,response)

    msg = receive do
      {:ssl,_socket,data} -> data
    end

    msg


  end


  defp get_value_from_key(parsed_list,key) do
    {^key, value} = Enum.find(parsed_list, fn {keyval, _value} -> if keyval == key do true end end)
    value
  end

  defp compute_key(key) do
    key = key <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    :crypto.hash(:sha, key) |> Base.encode64
  end

  defp compute_response(computed_key) do
    "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " <> computed_key <> "\r\n\r\n"
  end



end
