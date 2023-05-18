-module(mb).

-export([start/0]).

start() ->
  Pid = spawn_link(fun() -> loop(#{}) end),
  register(message_broker, Pid),
  {ok, Pid}.

loop(LoggedConsumers) ->
  receive
    {consack, Socket} ->
      dq_supervisor:send_ack(
        maps:get(Socket, LoggedConsumers));
    {logoff, Socket} ->
      case maps:is_key(Socket, LoggedConsumers) of
        true ->
          dq_supervisor:stop_queue(
            maps:get(Socket, LoggedConsumers)),
          loop(maps:remove(Socket, LoggedConsumers));
        _ ->
          loop(LoggedConsumers)
      end;
    {consumer, Socket, JsonMap} ->
      loop(handle_consumer(Socket, JsonMap, LoggedConsumers));
    {producer, Socket, JsonMap} ->
      handle_producer(Socket, JsonMap);
    Msg ->
      dead_letter ! {unknown, Msg}
  end,
  loop(LoggedConsumers).

handle_consumer(Socket, #{<<"login">> := ConsumerName} = _JsonMap, LoggedConsumers) ->
  case maps:is_key(Socket, LoggedConsumers) of
    true ->
      gen_tcp:send(Socket, "Already logged in\r\n"),
      LoggedConsumers;
    _ ->
      Users = maps:values(LoggedConsumers),
      case lists:member(ConsumerName, Users) of
        true ->
          gen_tcp:send(Socket, "User already logged in\r\n"),
          LoggedConsumers;
        _ ->
          dq_supervisor:start_queue(ConsumerName, Socket),
          gen_tcp:send(Socket, "Logged in\r\n"),
          maps:put(Socket, ConsumerName, LoggedConsumers)
      end
  end;
handle_consumer(Socket, JsonMap, LoggedConsumers) ->
  case maps:is_key(Socket, LoggedConsumers) of
    true ->
      spawn(fun() -> handle_logged_consumer(Socket, JsonMap, maps:get(Socket, LoggedConsumers))
            end);
    _ ->
      gen_tcp:send(Socket, "Please log in first\r\n")
  end,
  LoggedConsumers.

handle_logged_consumer(Socket,
                       #{<<"subscribe">> := TopicName} = _JsonMap,
                       ConsumerName) ->
  case db:consumer_subscribe(ConsumerName, TopicName) of
    topic_not_found ->
      gen_tcp:send(Socket, "Topic not found\r\n");
    already_subscribed ->
      gen_tcp:send(Socket, "Already subscribed\r\n");
    _ ->
      ok
  end;
handle_logged_consumer(Socket,
                       #{<<"unsubscribe">> := TopicName} = _JsonMap,
                       ConsumerName) ->
  case db:consumer_unsubscribe(ConsumerName, TopicName) of
    not_found ->
      gen_tcp:send(Socket, "Topic not found\r\n");
    _ ->
      ok
  end;
handle_logged_consumer(Socket, JsonMap, _) ->
  dead_letter ! {consumer, JsonMap},
  gen_tcp:send(Socket,
               "Json is valid but has invalid properties, should be {\"login\":Strin"
               "g} or {\"subscribe\":String} or {\"unsubscribe\":String}\r\n").

handle_producer(Socket, #{<<"topic">> := Topic, <<"message">> := Message} = _JsonMap) ->
  ok = db:upsert_topic_message(Topic, Message),
  gen_tcp:send(Socket, "PUBACK\r\n");
handle_producer(Socket, JsonMap) ->
  dead_letter ! {producer, JsonMap},
  gen_tcp:send(Socket,
               "Json is valid but has invalid properties, should be {\"topic\":Strin"
               "g, \"message\":String}\r\n").
