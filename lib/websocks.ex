defmodule Websocks do
  use Bitwise

  @moduledoc """
  Documentation for `Websocks`.
  """

  def accept() do
    # setup socket
    :ssl.start()

    {:ok, listenSocket} =
      :ssl.listen(9999,
        certfile: ".certs/cert.pem",
        keyfile: ".certs/key.pem",
        reuseaddr: true,
        password: 'pass'
      )

    {:ok, tlsSocket} = :ssl.transport_accept(listenSocket)
    {:ok, socket} = :ssl.handshake(tlsSocket)
    # recieve upgrade request
    request =
      receive do
        {:ssl, {:sslsocket, {:gen_tcp, _port, :tls_connection, _}, _}, request} -> request
      end

    # parse request

    parsed_request =
      String.split(to_string(request), "\r\n", trim: true)
      |> Enum.filter(fn val ->
        String.starts_with?(val, [
          "Host",
          "Sec-WebSocket-Version",
          "Sec-WebSocket-Extensions",
          "Sec-WebSocket-Key",
          "Upgrade"
        ])
      end)
      |> Enum.map(fn val -> val |> String.split(": ", trim: true, parts: 2) |> List.to_tuple() end)

    parameters = [
      host: get_value_from_key(parsed_request, "Host"),
      version: get_value_from_key(parsed_request, "Sec-WebSocket-Version"),
      extensions: get_value_from_key(parsed_request, "Sec-WebSocket-Extensions"),
      key: get_value_from_key(parsed_request, "Sec-WebSocket-Key"),
      upgrade: get_value_from_key(parsed_request, "Upgrade")
    ]

    # upgrade to WebSocket
    if parameters[:upgrade] != "websocket" do
      :ssl.close(socket)
    end

    response =
      parameters[:key]
      |> compute_key
      |> compute_response

    :ssl.send(socket, response)

    # recieve first message and parse it

    data =
      receive do
        {:ssl, _socket, data} -> data
      end
      |> list_to_bitstring

    <<_fin::1, _rsv::3, _opcode::4, masked::1, rest::bitstring>> = data

    if masked == 0 do
      :ssl.close(socket)
    end

    {payload_length, rest} = get_payload_length(rest)

    <<mask1, mask2, mask3, mask4, masked_payload::binary>> = rest
    mask = [mask1, mask2, mask3, mask4]

    payload = unmask_payload(mask, masked_payload)
    # check if payload length is the same as actual length
    if String.length(payload) != payload do
      String.slice(payload, -payload_length, payload_length)
    end

    socket
  end

  defp get_value_from_key(parsed_list, key) do
    {^key, value} =
      Enum.find(parsed_list, fn {keyval, _value} ->
        if keyval == key do
          true
        end
      end)

    value
  end

  defp compute_key(key) do
    key = key <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    :crypto.hash(:sha, key) |> Base.encode64()
  end

  defp compute_response(computed_key) do
    "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " <>
      computed_key <> "\r\n\r\n"
  end

  defp list_to_bitstring(list) do
    Enum.reduce(list, <<>>, fn value, acc -> acc <> <<value>> end)
  end

  defp get_payload_length(payload_rest) do
    <<length::7, rest::bitstring>> = payload_rest

    if length <= 125 do
      {length, rest}
    else
      if length == 126 do
        <<_length::7, extended_length::16, rest::bitstring>> = payload_rest
        {extended_length, rest}
      else
        if length == 127 do
          <<_length::7, extended_length::64, rest::bitstring>> = payload_rest
          {extended_length, rest}
        end
      end
    end
  end

  defp unmask_payload(mask, payload, acc \\ <<>>)

  defp unmask_payload(mask, <<payload_head, payload::binary>>, acc) do
    {mask_key, mask} = List.pop_at(mask, 0)
    acc = <<payload_head ^^^ mask_key>> <> acc
    mask = List.insert_at(mask, 4, mask_key)
    unmask_payload(mask, payload, acc)
  end

  defp unmask_payload(_mask, _payload, acc) do
    String.reverse(acc)
  end

  def send(socket, msg_content) do
    msg_length = String.length(msg_content)

    msg =
      cond do
        msg_length <= 125 ->
          <<1::1, 0::3, 1::4, 0::1, msg_length::7, msg_content::bitstring>>

        msg_length <= 65536 ->
          <<1::1, 0::3, 1::4, 0::1, 126::7, msg_length::16, msg_content::bitstring>>

        # works in theory, but not in practice
        msg_length > 65536 ->
          <<1::1, 0::3, 1::4, 0::1, 127::7, msg_length::64, msg_content::bitstring>>
      end

    :ssl.send(socket, msg)
  end

  def ping(socket) do
    :ssl.send(socket, <<1::1, 0::3, 1001::4, 0::1, 0::7>>)
  end

  def pong(socket) do
    :ssl.send(socket, <<1::1, 0::3, 1010::4, 0::1, 0::7>>)
  end
end
