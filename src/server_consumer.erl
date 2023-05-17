-module(server_consumer).

-export([start/1]).

start(Port) ->
  {ok, Socket} = gen_tcp:listen(Port, [binary, {active, false}]),
  Pid = spawn_link(fun() -> accept(Socket) end),
  {ok, Pid}.

accept(ListenSocket) ->
  case gen_tcp:accept(ListenSocket) of
    {ok, Socket} ->
      Pid =
        spawn(fun() ->
                 io:format("Connection accepted ~n", []),
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
      io:format("Got packet: ~p~n", [Data]),
      gen_tcp:send(Socket, Data),
      loop(Socket);
    {tcp_closed, Socket} ->
      io:format("Socket ~p closed~n", [Socket]);
    {tcp_error, Socket, Reason} ->
      io:format("Error on socket ~p reason: ~p~n", [Socket, Reason])
  end.

