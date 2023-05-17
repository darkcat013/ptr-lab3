-module(db).

-export([init/0]).

init() ->
  dets:open_file(topic_messages,[{file, "topic_messages.dets"}]),
  dets:open_file(consumer_queues,[{file, "consumer_queues.dets"}]),
  dets:open_file(topic_subscribers,[{file, "topic_subscribers.dets"}]),
  ok.