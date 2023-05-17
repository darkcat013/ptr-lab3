-module(server_supervisor).

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

  ServerProducer =
    #{id => server_producer,
      start => {server_producer, start, [4010]},
      restart => permanent,
      modules => [server_producer]},
  ServerConsumer =
    #{id => server_consumer,
      start => {server_consumer, start, [4011]},
      restart => permanent,
      modules => [server_consumer]},
  ChildSpecs = [ServerProducer, ServerConsumer],
  {ok, {SupFlags, ChildSpecs}}.
