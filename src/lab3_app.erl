-module(lab3_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  ok = db:init(),
  ok = quickrand:seed(),
  lab3_sup:start_link().

stop(_State) ->
  ok.
