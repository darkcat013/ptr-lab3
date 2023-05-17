-module(json_helper).

-export([try_decode/1]).

try_decode(BinaryString) ->
  try
    {true, jsx:decode(BinaryString)}
  catch
    _:_ ->
      {false}
  end.
