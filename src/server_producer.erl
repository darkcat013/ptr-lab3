-module(server_producer).

-export([start/1]).

start(Port) ->
  {ok, Socket} = gen_tcp:listen(Port, [binary, {active, false}]),
  Pid = spawn_link(fun() -> accept(Socket) end),
  {ok, Pid}.

accept(ListenSocket) ->
  case gen_tcp:accept(ListenSocket) of
    {ok, Socket} ->
      io:format("Producer Server | New connection: ~p~n", [Socket]),
      Pid =
        spawn(fun() ->
                 gen_tcp:send(Socket, "Connection accepted\r\n"),
                 loop(Socket)
              end),
      gen_tcp:controlling_process(Socket, Pid),
      accept(ListenSocket);
    Error ->
      exit(Error)
  end.

loop(Sock) ->
  inet:setopts(Sock, [{active, once}]),
  receive
    {tcp, Socket, Data} ->
      io:format("Producer Server | Got packet from ~p: ~p~n", [Socket, Data]),
      case json_helper:try_decode(Data) of
        {true, JsonMap} ->
          message_broker ! {producer, Socket, JsonMap};
        _ ->
          dead_letter ! {producer, Data},
          gen_tcp:send(Socket, "Invalid json, try again\r\n")
      end,
      loop(Socket);
    {tcp_closed, Socket} ->
      io:format("Producer Server | Connection ~p closed~n", [Socket]);
    {tcp_error, Socket, Reason} ->
      io:format("Producer Server | Error on connection ~p reason: ~p~n", [Socket, Reason])
  end.
