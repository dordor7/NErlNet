%%%-------------------------------------------------------------------
%%% @author kapelnik
%%% @copyright (C) 2021, Nerlnet
%%% @doc
%%%
%%% @end
%%% Created : 01. Jan 2021 4:58 AM
%%%-------------------------------------------------------------------
-module(jsonHandler).
-author("kapelnik").
-define(JSON_ADDR, "/usr/local/lib/nerlnet-lib/NErlNet/src_erl/Communication_Layer/http_Nerlserver/").

%% API
-export([init/2, multipart/2]).
% This handler waits for an http request from python. the syntax should be as follow:
%From python:
% response = requests.post('http://localhost:8484/updateJsonPath', data='../../../jsonPath')
%From erlang(maybe for debug):
%%httpc:request(post,{"http://localhost:8484/updateJsonPath", [],"application/x-www-form-urlencoded","../../../jsonPath"}, [], []).

%%%%%% Getting files in multipart format.
init(Req0, [ApplicationPid]) ->
  deleteOldJson("arch.json"),
  deleteOldJson("conn.json"),
  {_Req, _Data} = multipart(Req0, []),  % get files from Req
  %io:format("got Req: ~p~nData: ~p~n",[Req, Data]),
  %{ok,Body,_} = cowboy_req:read_body(Req0),
  ApplicationPid ! {jsonAddress,{fileReady,fileReady}},
  Reply = io_lib:format("nerlnet starting", []),

  Req2 = cowboy_req:reply(200,
    #{<<"content-type">> => <<"text/plain">>},
    Reply,
    Req0),
  {ok, Req2, ApplicationPid}.


% returns {FullReq, Data} / {FullReq, [fileReady]}
multipart(Req0, Data) ->
case cowboy_req:read_part(Req0) of
    {ok, Headers, Req1} ->
        {Req, BodyData} = case cow_multipart:form_data(Headers) of
            %% The multipart message contains normal/basic data
            {data, _FieldName} ->
                {ok, Body, Req2} = cowboy_req:read_part_body(Req1),
                {Req2, Body};
            %% The message contains a file
            {file, FieldName, _Filename, _CType} ->
                {ok, File} = file:open(FieldName, [append]),
                Req2 = stream_file(Req1, File),
                {Req2, [fileReady]}
        end,
        multipart(Req, Data++BodyData);
    {done, Req} ->
        {Req, Data}
end.

stream_file(Req0, File) ->
    case cowboy_req:read_part_body(Req0) of
        {ok, LastBodyChunk, Req} ->
            file:write(File, LastBodyChunk),
            file:close(File),
            Req;
        {more, BodyChunk, Req} ->
            file:write(File, BodyChunk),
            stream_file(Req, File)
    end.

deleteOldJson(Filename) ->
  try file:delete(?JSON_ADDR++Filename)
  catch
    {error, E} -> io:format("couldn't delete file ~p, beacuse ~p~n",[Filename, E])
  end.