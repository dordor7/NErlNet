%%%-------------------------------------------------------------------
%%% @author kapelnik
%%% @copyright (C) 2021, Nerlnet
%%% @doc
%%%
%%% @end
%%% Created : 19. Apr 2021 4:27 AM
%%%-------------------------------------------------------------------
-module(parser).
-author("kapelnik").

%% API
-define(TMP_DATA_ADDR, "tmpData.csv").
-export([parse/2, parseCSV/2, deleteTMPData/0]).

parseCSV(ChunkSize, CSVData)->
  %io:format("curr dir: ~p~n",[file:get_cwd()]),
  deleteTMPData(),    % ideally do this when getting a fresh CSV (finished train -> start predict)

  try
    file:write_file(?TMP_DATA_ADDR, CSVData),
    logger:notice("created tmpData.csv"), parse_file(ChunkSize, ?TMP_DATA_ADDR)
  catch
    {error,Er} -> logger:error("couldn't write file ~p, beacuse ~p",[?TMP_DATA_ADDR, Er])
  end.

deleteTMPData() ->
  try file:delete(?TMP_DATA_ADDR) 
  catch
    {error, E} -> logger:notice("couldn't delete file ~p, beacuse ~p",[?TMP_DATA_ADDR, E])
  end.


%%use this decoder to decode one line after parsing
%%    decodeList(Binary)->  decodeList(Binary,[]).
%%    decodeList(<<>>,L) -> L;
%%    decodeList(<<A:64/float,Rest/binary>>,L) -> decodeList(Rest,L++[A]).

%%this parser takes a CSV folder containing chunked data, parsing into a list of binary.
%%each record in the line is a batch of samples
parse(ChunkSize,FolderName)->
  io:format("curr dir: ~p~n",[file:get_cwd()]),
%%  FolderName="./input/shuffled-input1_splitted/",
  parse_all(ChunkSize,FolderName,1,[]).


parse_all(ChunkSize,FolderName,Counter,Ret)->
  Name = lists:last(re:split(FolderName,"/",[{return,list}])),

  try   parse_file(ChunkSize,"../../../inputDataDir/"++FolderName++"_splitted/"++Name++"_splitted"++integer_to_list(Counter)++".csv") of

    L ->
      parse_all(ChunkSize,FolderName,Counter+1,Ret++L)
  catch error: E->
    if length(Ret) == 0  ->
        io:format("#####Error at Parser: ~n~p~n",[E]);
    true -> Ret
  end
  end.

%%parsing a given CSV file
parse_file(ChunkSize,File_Address) ->

    io:format("File_Address:~p~n~n",[File_Address]),

  {ok, Data} = file:read_file(File_Address),
  Lines = re:split(Data, "\r|\n|\r\n", [{return,binary}] ),

  SampleSize = length(re:split(binary_to_list(hd(Lines)), ",", [{return,list}])),
%%  get binary lines
  ListsOfListsOfFloats = encodeListOfLists(Lines),

%%chunk data
  Chunked= makeChunks(ListsOfListsOfFloats,ChunkSize,ChunkSize,<<>>,[],SampleSize),
%%  io:format("Chunked!~n",[]),
%%%%  Decoded = decodeListOfLists(Chunked ),
%%
%%  io:format("Decoded!!!: ~n",[]),
  Chunked.

encodeListOfLists(L)->encodeListOfLists(L,[]).
encodeListOfLists([],Ret)->
  Ret;
encodeListOfLists([[<<>>]|Tail],Ret)->
  encodeListOfLists(Tail,Ret);
encodeListOfLists([Head|Tail],Ret)->
  encodeListOfLists(Tail,Ret++[encodeFloatsList(Head)]).


%%return a binary representing a list of floats: List-> <<binaryofthisList>>
encodeFloatsList(L)->
  Splitted = re:split(binary_to_list(L), ",", [{return,list}]),
  encodeFloatsList(Splitted,<<>>).
encodeFloatsList([],Ret)->Ret;
encodeFloatsList([<<>>|ListOfFloats],Ret)->
  encodeFloatsList(ListOfFloats,Ret);
encodeFloatsList([[]|ListOfFloats],Ret)->
  encodeFloatsList(ListOfFloats,Ret);
encodeFloatsList([H|ListOfFloats],Ret)->
  %%%%%%%% possible bug in reading csv. numbers sometime appear as ".7" / "-.1" 
  Num = case H of
    [$-,$.|Rest]  -> "-0."++Rest;
    [$.|Rest]     -> "0."++Rest;
    List          -> List
  end,

  try list_to_float(Num) of
    Float->
      encodeFloatsList(ListOfFloats,<<Ret/binary,Float:64/float>>)
  catch
    error:_Error->
      Integer = list_to_integer(Num),
      encodeFloatsList(ListOfFloats,<<Ret/binary,Integer:64/float>>)

  end.

%% for each batch, make it a tensor by adding header: x,y,z,<<>>,data
makeChunks(L,1,1,_,_,_SampleSize) ->L;
makeChunks([],_Left,_ChunkSize,Acc,Ret,_SampleSize) ->
  Ret++[Acc];

makeChunks([Head|Tail],1,ChunkSize,Acc,Ret,SampleSize) ->
  makeChunks(Tail,ChunkSize,ChunkSize,<<>>,Ret++[<<ChunkSize:64/float,SampleSize:64/float,1:64/float,Acc/binary,Head/binary>>],SampleSize);

makeChunks([Head|Tail],Left,ChunkSize,Acc,Ret,SampleSize) ->
  makeChunks(Tail,Left-1,ChunkSize,<<Acc/binary,Head/binary>>,Ret,SampleSize).
