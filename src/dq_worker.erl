-module(dq_worker).

-export([start/2]).

start(ConsumerName, Socket) ->
  db:create_consumer_topics(ConsumerName),
  Pid = spawn_link(fun() -> loop(ConsumerName, Socket) end),
  {ok, Pid}.

loop(ConsumerName, Socket) ->
  TopicsMap = db:get_consumer_topics_map(ConsumerName),
  maps:foreach(fun(K, V) -> for_each(ConsumerName, Socket, K, V) end, TopicsMap),
  loop(ConsumerName, Socket).

for_each(ConsumerName, Socket, Key, Value) ->
  case db:get_topic_message_by_index(Key, Value) of
    no_new_messages ->
      ok;
    Message ->
      gen_tcp:send(Socket,
                   iolist_to_binary(["Topic: ", Key, "\r\nMessage: ", Message, "\r\n"])),
      Result = db:consumer_increment_topic_index(ConsumerName, Key),
      io:format("~p~n", [Result]);
    _ ->
      io:format("error")
  end.
