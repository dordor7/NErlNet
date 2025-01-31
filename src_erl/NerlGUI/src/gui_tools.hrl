-include_lib("wx/include/wx.hrl").

-record(state, {mainGen, frame, objs, nerlGraph}).

-define(FONT_SIZE, 15).
-define(PADDING_W, 20).
-define(PADDING_H, 30).
-define(TILE_W, 200).
-define(TILE_H, 200).
-define(TILE_W(Mult), round(?TILE_W*Mult)).
-define(TILE_H(Mult), round(?TILE_H*Mult)).
-define(BUTTON_SIZE(Mult), {size, {round(?TILE_W*Mult), round(?TILE_H*Mult)}}).
-define(BUTTON_LOC(Row, Col), 
    {pos, {round((Col+1) * ?PADDING_H + Col * ?TILE_H), round((Row+1) * ?PADDING_W + Row * ?TILE_W)}}).

-define(PROBE_TIME, 1000).
