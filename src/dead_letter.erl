-module(dead_letter).

-export([start/0]).

start() ->
  Pid = spawn_link(fun() -> loop() end),
  register(dead_letter, Pid),
  {ok, Pid}.

loop() ->
  receive
    {From, Msg} ->
      db:insert_dead_letter(From, Msg)
  end,
  loop().
