-module(dq_supervisor).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).
-export([start_queue/2, stop_queue/1, get_children/0]).

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
  {ok, {SupFlags, []}}.

start_queue(ConsumerName, Socket) ->
    supervisor:start_child(?MODULE,
                           #{id => ConsumerName,
                             start => {dq_worker, start, [ConsumerName, Socket]},
                             restart => permanent,
                             shutdown => 2000,
                             type => worker,
                             modules => [dq_worker]}).

stop_queue(ConsumerName) ->
  supervisor:terminate_child(?MODULE, ConsumerName).

get_children() ->
  supervisor:which_children(?MODULE).
