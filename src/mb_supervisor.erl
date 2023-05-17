-module(mb_supervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
  MaxRestarts = 3,
  MaxTime = 1,
  SupFlags =
    #{strategy => one_for_one,
      intensity => MaxRestarts,
      period => MaxTime},

  MessageBroker =
    #{id => mb,
      start => {mb, start, []},
      restart => permanent,
      modules => [mb]},
  DeadLetter =
    #{id => dead_letter,
      start => {dead_letter, start, []},
      restart => permanent,
      modules => [dead_letter]},
  DurableQueueSupervisor =
    #{id => dq_supervisor,
      start => {dq_supervisor, start, []},
      restart => permanent,
      type => supervisor,
      modules => [dq_supervisor]},
  ChildSpecs = [MessageBroker],% DeadLetter, DurableQueueSupervisor],
  {ok, {SupFlags, ChildSpecs}}.
