-module(db).

-export([init/0, get_all_topic_messages/0, get_topic_messages/1,
         get_topic_message_by_index/2, upsert_topic_message/2, get_all_consumer_topics/0,
         get_consumer_topics/1, get_consumer_topics_map/1, create_consumer_topics/1,
         consumer_subscribe/2, consumer_unsubscribe/2, consumer_increment_topic_index/2,
         get_all_dead_letter/0, insert_dead_letter/2]).
-export([reset/0]).

init() ->
  dets:open_file(topic_messages_table, [{file, "topic_messages.dets"}]),
  dets:open_file(consumer_topics_table, [{file, "consumer_topics.dets"}]),
  dets:open_file(dead_letter_table, [{file, "dead_letter.dets"}]),
  ok.

% TOPIC MESSAGES
get_all_topic_messages() ->
  dets:match_object(topic_messages_table, '_').

get_topic_messages(TopicName) ->
  dets:lookup(topic_messages_table, {id, TopicName}).

get_topic_message_by_index(TopicName, Index) ->
  [{_Id, {messages, Messages}}] = get_topic_messages(TopicName),
  case Index > length(Messages) of
    true ->
      no_new_messages;
    _ ->
      lists:nth(Index, Messages)
  end.

upsert_topic_message(TopicName, Message) ->
  case get_topic_messages(TopicName) of
    [] ->
      dets:insert(topic_messages_table, {{id, TopicName}, {messages, [Message]}});
    [{_Id, {messages, Messages}}] ->
      dets:insert(topic_messages_table, {{id, TopicName}, {messages, Messages ++ [Message]}})
  end.

% CONSUMER TOPICS INDEXES
get_all_consumer_topics() ->
  dets:match_object(consumer_topics_table, '_').

get_consumer_topics(ConsumerName) ->
  dets:lookup(consumer_topics_table, {id, ConsumerName}).

get_consumer_topics_map(ConsumerName) ->
  [{_Id, {topics, TopicsMap}}] = get_consumer_topics(ConsumerName),
  TopicsMap.

create_consumer_topics(ConsumerName) ->
  case get_consumer_topics(ConsumerName) of
    [] ->
      dets:insert(consumer_topics_table, {{id, ConsumerName}, {topics, #{}}});
    _ ->
      consumer_topics_exists
  end.

consumer_subscribe(ConsumerName, TopicName) ->
  case get_topic_messages(TopicName) of
    [] ->
      topic_not_found;
    _Row ->
      TopicsMap = get_consumer_topics_map(ConsumerName),
      case maps:is_key(TopicName, TopicsMap) of
        true ->
          already_subscribed;
        _ ->
          dets:insert(consumer_topics_table,
                      {{id, ConsumerName}, {topics, maps:put(TopicName, 1, TopicsMap)}})
      end
  end.

consumer_unsubscribe(ConsumerName, TopicName) ->
  TopicsMap = get_consumer_topics_map(ConsumerName),
  case maps:is_key(TopicName, TopicsMap) of
    true ->
      dets:insert(consumer_topics_table,
                  {{id, ConsumerName}, {topics, maps:remove(TopicName, TopicsMap)}});
    _ ->
      not_found
  end.

consumer_increment_topic_index(ConsumerName, TopicName) ->
  TopicsMap = get_consumer_topics_map(ConsumerName),
  case maps:is_key(TopicName, TopicsMap) of
    true ->
      Index = maps:get(TopicName, TopicsMap),
      dets:insert(consumer_topics_table,
                  {{id, ConsumerName}, {topics, maps:put(TopicName, Index + 1, TopicsMap)}});
    _ ->
      subscribed_topic_not_found
  end.

% DEAD LETTER
get_all_dead_letter() ->
  dets:match_object(dead_letter_table, '_').

insert_dead_letter(From, Msg) ->
  true = dets:insert_new(dead_letter_table, auditable(From, Msg)).

% help functions

auditable(From, Msg) ->
  {{id, uuid()}, {from, From}, {time, calendar:universal_time()}, {message, {Msg}}}.

uuid() ->
  uuid:uuid_to_string(
    uuid:get_v4_urandom()).

reset_tm() ->
  dets:delete_all_objects(topic_messages_table).
reset_ct() ->
  dets:delete_all_objects(consumer_topics_table).
reset_dl() ->
  dets:delete_all_objects(dead_letter_table).
reset() ->
  reset_tm(),
  reset_ct(),
  reset_dl().
