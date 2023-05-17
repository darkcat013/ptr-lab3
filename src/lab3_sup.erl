-module(lab3_sup).

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

  ServerSupervisor =
    #{id => server_supervisor,
      start => {server_supervisor, start_link, []},
      restart => permanent,
      type => supervisor,
      modules => [server_supervisor]},

  MessageBrokerSupervisor =
    #{id => mb_supervisor,
      start => {mb_supervisor, start_link, []},
      restart => permanent,
      type => supervisor,
      modules => [mb_supervisor]},
  ChildSpecs = [ServerSupervisor, MessageBrokerSupervisor],
  {ok, {SupFlags, ChildSpecs}}.
