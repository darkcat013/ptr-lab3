-module(mb).

-export([start/0]).

start() ->
  Pid = spawn_link(fun() -> loop() end),
  register(message_broker, Pid),
  {ok, Pid}.

loop() ->
  receive
    M ->
      io:format("~p~n", [M])
  end,
  loop().
