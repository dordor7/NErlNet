%%%-------------------------------------------------------------------
%%% @author kapelnik
%%% @copyright (C) 2021, Nerlnet
%%% @doc
%%%
%%% @end
%%% Created : 14. May 2021 4:48 AM
%%%-------------------------------------------------------------------
-module(jsonParser).
-author("kapelnik").
-export([getDeviceEntities/3]).
-define(ARCH_ADDR, "/usr/local/lib/nerlnet-lib/NErlNet/src_erl/Communication_Layer/http_Nerlserver/arch.json").
-define(COMM_ADDR, "/usr/local/lib/nerlnet-lib/NErlNet/src_erl/Communication_Layer/http_Nerlserver/conn.json").
-define(FILE_IDENTIFIER,"[jsonParser] ").

getDeviceEntities(_ArchitectureAdderess,_CommunicationMapAdderess, HostName)->

  {ok, ArchitectureAdderessData} = file:read_file(?ARCH_ADDR),
  {ok, CommunicationMapAdderessData} = file:read_file(?COMM_ADDR),

%%TODO ADD CHECK FOR VALID INPUT:  
logger:notice(?FILE_IDENTIFIER++"IS THIS A JSON? ~p~n",[jsx:is_json(ArchitectureAdderessData)]),

  %%Decode Json to architecute map and Connection map:
  ArchitectureMap = jsx:decode(ArchitectureAdderessData,[]),
  _CommunicationMap= jsx:decode(CommunicationMapAdderessData,[]),

% Get NerlNetSettings, batch size, frequency etc..
  NerlNetSettings = maps:get(<<"NerlNetSettings">>,ArchitectureMap),

  %%  get workers to clients map
  WorkersMap = getWorkersMap(maps:get(<<"clients">>,ArchitectureMap),#{}),

  %%  retrive THIS device entities
  OnDeviceEntities1 = getOnDeviceEntities(maps:get(<<"devices">>,ArchitectureMap),HostName),
  OnDeviceEntities = re:split(binary_to_list(OnDeviceEntities1),",",[{return,list}]),
  %%  io:format("OnDeviceEntities:~n~p~n",[OnDeviceEntities]),

  %%This function returns a graph G, represents all the connections in nerlnet. each entitie should have a copy of it.
  G = buildCommunicationGraph(?ARCH_ADDR,?COMM_ADDR),

  %%  retrive THIS device Clients And Workers, returns a list of tuples:[{ClientArgumentsMap,WorkersMap,ConnectionMap},..]
  ClientsAndWorkers = getClients(maps:get(<<"clients">>,ArchitectureMap),OnDeviceEntities , [],maps:get(<<"workers">>,ArchitectureMap),ArchitectureMap,G),

  %%  retrive THIS device Sources, returns a list of tuples:[{SourceArgumentsMap, ConnectionMap},..]
  Sources = {getSources(maps:get(<<"sources">>, ArchitectureMap), OnDeviceEntities, [], ArchitectureMap,G),WorkersMap},

  %%  retrive THIS device Routers, returns a list of tuples:[{RoutersArgumentsMap, ConnectionMap},..]
  Routers = getRouters(maps:get(<<"routers">>,ArchitectureMap),OnDeviceEntities , [],ArchitectureMap,G),

  Federateds = {getFederated(maps:get(<<"federated">>,ArchitectureMap),OnDeviceEntities , [],ArchitectureMap,G),WorkersMap},

  GUI_on_dev = lists:member("nerlGUI",OnDeviceEntities),
  GUI = if GUI_on_dev -> maps:get(<<"nerlGUI">>,ArchitectureMap); true -> none end,

  %%  retrive THIS device MainServer, returns a map of arguments

%%  check if a mainServer needed to be opened on this device, retrive arguments for main server or return none atom
  OnDevice = lists:member("mainServer",OnDeviceEntities),
  if
    OnDevice == false -> MainServer = none;
    true -> MainServerArgs = maps:get(<<"mainServer">>,ArchitectureMap),
      ClientsNames = getAllClientsNames(maps:get(<<"clients">>,ArchitectureMap),[]),
      % MainServerConnectionsMap=getConnectionMap(<<"mainServer">>,ArchitectureMap,G),
      % add GUI connection to MainServer, if it exists
      if GUI /= none -> addEdges(G, "mainServer", "nerlGUI");
        true -> none end,
      MainServer = {MainServerArgs,G,WorkersMap,ClientsNames}
  end,



  %%  retrive  a map of arguments of the API Server
  ServerAPI = maps:get(<<"serverAPI">>,ArchitectureMap),
  %io:format("All Edges In Nerlnet Graph:~n~p~n",[[digraph:edge(G,E) || E <- digraph:edges(G)]]),
  %io:format("path:~n~p~n",[digraph:get_short_path(G,"serverAPI","c1")]),


  %io:format("On Device Entities to Open:~nMainServer: ~p~nServerAPI: ~p~nClientsAndWorkers: ~p~nSources: ~p~nRouters: ~p~n Federated Servers: ~p~n",
  %                                    [MainServer,ServerAPI,ClientsAndWorkers,Sources,Routers,Federateds]),

  
  {MainServer,ServerAPI,ClientsAndWorkers,Sources,Routers,Federateds,NerlNetSettings,GUI}.



%%getEntities findes the right device from devices map and returns it's entities
getOnDeviceEntities([],_HostName) -> none;
getOnDeviceEntities([Device|Tail],HostName) ->
  DevHost = maps:get(<<"host">>,Device),
  if HostName == DevHost ->
    maps:get(<<"entities">>,Device);
    true -> getOnDeviceEntities(Tail,HostName)
  end.

%%getSources findes all sources needed to be opened on this device. returns [{sourceArgsMap,SourceConnectionMap},...]
getFederated([],_OnDeviceSources,[],_ArchMap,_G) ->none;
getFederated([],_OnDeviceSources,Return,_ArchMap,_G) ->Return;
getFederated([Federated|Federateds],OnDeviceFederated,Return,ArchMap,G) ->

  FederatedName = maps:get(<<"name">>,Federated),
  OnDevice = lists:member(binary_to_list(FederatedName),OnDeviceFederated),
  if  OnDevice == false->
    getFederated(Federateds,OnDeviceFederated,Return,ArchMap,G);
    true ->
      %ConnectionsMap = getConnectionMap(maps:get(<<"name">>,Federated),ArchMap,G),
      getFederated(Federateds,OnDeviceFederated,Return++[{Federated,G}],ArchMap,G)
  end.

getSources([],_OnDeviceSources,[],_ArchMap,_G) ->none;
getSources([],_OnDeviceSources,Return,_ArchMap,_G) ->Return;
getSources([Source|Sources],OnDeviceSources,Return,ArchMap,G) ->

  SourceName = maps:get(<<"name">>,Source),
  OnDevice = lists:member(binary_to_list(SourceName),OnDeviceSources),
  if  OnDevice == false->
    getSources(Sources,OnDeviceSources,Return,ArchMap,G);
    true ->
      %ConnectionsMap = getConnectionMap(maps:get(<<"name">>,Source),ArchMap,CommunicationMap),
      getSources(Sources,OnDeviceSources,Return++[{Source,G}],ArchMap,G)
  end.

%%getRouters findes all Routers needed to be opened on this device. returns [{RouterArgsMap,RoutersConnectionMap},...]
getRouters([],_OnDeviceRouters,[],_ArchMap,_G) ->none;
getRouters([],_OnDeviceRouters,Return,_ArchMap,_G) ->Return;
getRouters([Router|Routers],OnDeviceRouters,Return,ArchMap,G) ->

  RouterName = maps:get(<<"name">>,Router),
  OnDevice = lists:member(binary_to_list(RouterName),OnDeviceRouters),
  if  OnDevice == false->
    getRouters(Routers,OnDeviceRouters,Return,ArchMap,G);
    true ->
      %ConnectionsMap = getRouterConnectionMap(maps:get(<<"name">>,Router),ArchMap,CommunicationMap),
      getRouters(Routers,OnDeviceRouters,Return++[{Router,G}],ArchMap,G)
  end.

%%getClients findes all Clients And Workers needed to be opened on this device. returns [{ClientArgsMap,WorkersMap,ClientConnectionMap},...]
getClients([],_Entities,[],_ArchWorkers,_ArchMap,_G) ->none;
getClients([],_Entities,ClientsAndWorkers,_ArchWorkers,_ArchMap,_G) ->ClientsAndWorkers;
getClients([Client|Tail],Entities,ClientsAndWorkers,ArchWorkers,ArchMap,G) ->

  ClientName = maps:get(<<"name">>,Client),
  OnDevice = lists:member(binary_to_list(ClientName),Entities),
  if  OnDevice == false->
    getClients(Tail,Entities,ClientsAndWorkers,ArchWorkers,ArchMap,G);
    true ->
      %ConnectionsMap = getConnectionMap(maps:get(<<"name">>,Client),ArchMap,CommunicationMap),
      ClientWorkers =re:split(binary_to_list(maps:get(<<"workers">>,Client)),",",[{return,list}]),
      Workers = getWorkers(ArchWorkers,ClientWorkers,[]),
      getClients(Tail,Entities,ClientsAndWorkers++[{Client,Workers,G}],ArchWorkers,ArchMap,G)
  end.



getWorkers([],_ClientsWorkers,Workers) -> Workers;
getWorkers([Worker|Tail],ClientsWorkers,Workers) ->
  WorkerName = maps:get(<<"name">>,Worker),
  InClient = lists:member(binary_to_list(WorkerName),ClientsWorkers),
  if  InClient == false->
    getWorkers(Tail,ClientsWorkers,Workers);
    true ->
      getWorkers(Tail,ClientsWorkers,Workers++[Worker])
  end.

% getHost([DeviceMap|Devices],EntityName) ->
%   Entities = maps:get(<<"entities">>, DeviceMap),
%   OnDeviceEntities =re:split(binary_to_list(Entities),",",[{return,list}]),

%   OnDevice = lists:member(binary_to_list(EntityName),OnDeviceEntities),
%   if  OnDevice == false->
%     getHost(Devices,EntityName);
%     true ->
%       binary_to_list(maps:get(<<"host">>,DeviceMap))
%   end.

getPort([],_EntityName) -> false;
getPort([EntityMap|Entities],EntityName) ->
  CurrName = maps:get(<<"name">>, EntityMap),
  if  CurrName == EntityName->
    list_to_integer(binary_to_list(maps:get(<<"port">>, EntityMap)));
    true ->
      getPort(Entities,EntityName)
  end.


%%% TODO: make new port search func
% getPortUnknown(ArchMap, Name)->
%   case Name of
%     <<"mainServer">> -> [MainServer] = maps:get(<<"mainServer">>,ArchMap),list_to_integer(binary_to_list(maps:get(<<"port">>, MainServer)));
%     <<"serverAPI">> ->  [ServerAPI] = maps:get(<<"serverAPI">>,ArchMap),list_to_integer(binary_to_list(maps:get(<<"port">>, ServerAPI)));
%     <<"nerlGUI">> ->    [NerlGUI] = maps:get(<<"nerlGUI">>,ArchMap),list_to_integer(binary_to_list(maps:get(<<"port">>, NerlGUI)));
%     Other ->
%       case getPort(maps:get(<<"routers">>,ArchMap),EntityName) of

%   end.

getPortUnknown(ArchMap,<<"mainServer">>)->
  [MainServer] = maps:get(<<"mainServer">>,ArchMap),
  list_to_integer(binary_to_list(maps:get(<<"port">>, MainServer)));
getPortUnknown(ArchMap,<<"serverAPI">>)->
  [ServerAPI] = maps:get(<<"serverAPI">>,ArchMap),
  list_to_integer(binary_to_list(maps:get(<<"port">>, ServerAPI)));
getPortUnknown(ArchMap,<<"nerlGUI">>)->
  [NerlGUI] = maps:get(<<"nerlGUI">>,ArchMap),
  list_to_integer(binary_to_list(maps:get(<<"port">>, NerlGUI)));
getPortUnknown(ArchMap,EntityName)->
  FoundRouter = getPort(maps:get(<<"routers">>,ArchMap),EntityName),
  if  FoundRouter == false->
    Foundclient = getPort(maps:get(<<"clients">>,ArchMap),EntityName),
    if  Foundclient == false->
      Foundsources = getPort(maps:get(<<"sources">>,ArchMap),EntityName),
      if  Foundsources == false->
          getPort(maps:get(<<"federated">>,ArchMap),EntityName);
        true ->
          Foundsources
        end;
      true ->
        Foundclient
    end;
  true -> FoundRouter
  end.

%%returns a map of all workers  - key workerName, Value ClientName
getWorkersMap([],WorkersMap)->WorkersMap;
getWorkersMap([Client|Clients],WorkersMap)->
  ClientName = list_to_atom(binary_to_list(maps:get(<<"name">>,Client))),
  Workers = re:split(binary_to_list(maps:get(<<"workers">>,Client)),",",[{return,list}]),
  NewMap = addAll(Workers,WorkersMap,ClientName),
  getWorkersMap(Clients,NewMap).

addAll([],WorkersMap,_ClientName)->WorkersMap;
addAll([Worker|Workers],WorkersMap,ClientName)->
  addAll(Workers,maps:put(list_to_atom(Worker),ClientName,WorkersMap),ClientName).

%%returns a list of all clients names in nerlnet
getAllClientsNames([],ClientsNames) ->ClientsNames;
getAllClientsNames([Client|Tail],ClientsNames) ->
  ClientName = maps:get(<<"name">>,Client),
  getAllClientsNames(Tail,ClientsNames++[list_to_atom(binary_to_list(ClientName))]).


  %%New for DAG:

	%% This graph represents the connections withing NerlNet. edge=connection between two entities in the net, vertices = etities.
	%The vaule of each of the vertices contains the tuple {Host,Port} with the host and port of the cowboy server connected to the entitie.
	buildCommunicationGraph(ArchitectureAdderess,CommunicationMapAdderess)->
    
    %%Read and decode json files:
    {ok, ArchitectureAdderessData} = file:read_file(ArchitectureAdderess),
    ArchitectureMap = jsx:decode(ArchitectureAdderessData,[]),
    {ok, CommunicationMapAdderessData} = file:read_file(CommunicationMapAdderess),
    CommunicationMap= jsx:decode(CommunicationMapAdderessData,[]),

    %io:format("ArchitectureMap:~n~p~n",[ArchitectureMap]),
    %io:format("CommunicationMap:~n~p~n",[CommunicationMap]),

    %Start building the graph one device at a time, than connect all routers with communicationMap json.
    G = digraph:new(),
    ListOfHosts = getAllHosts(ArchitectureMap),
    [addDeviceToGraph(G,ArchitectureMap, HostName)||HostName <- ListOfHosts],
    connectRouters(G,ArchitectureMap,CommunicationMap),

    %%connect serverAPI to Main Server
    [ServerAPI] = maps:get(<<"serverAPI">>,ArchitectureMap),
    ServerAPIHost = binary_to_list(maps:get(<<"host">>,ServerAPI)),
    ServerAPIPort = list_to_integer(binary_to_list(maps:get(<<"port">>,ServerAPI))),
    digraph:add_vertex(G,"serverAPI", {ServerAPIHost,ServerAPIPort}),
    addEdges(G,"serverAPI","mainServer"),
    
    %%return G
    G .

addDeviceToGraph(G,ArchitectureMap, HostName)->


    OnDeviceEntities1 = getOnDeviceEntities(maps:get(<<"devices">>,ArchitectureMap),HostName),
    OnDeviceEntities =re:split(binary_to_list(OnDeviceEntities1),",",[{return,list}]),
    logger:notice(?FILE_IDENTIFIER++"adding device ~p to graph~n",[OnDeviceEntities]),

    %%ADD THIS TO NERLNET:

    % Routers = [binary_to_list(maps:get(<<"name">>,Router))||Router <- maps:get(<<"routers">>,ArchitectureMap)],
    % io:format("Routers:~n~p~n",[Routers]),

    % MyRouter = getMyRouter(Routers,OnDeviceEntities), TODO remove
    % MyRouterPort = getPort(maps:get(<<"routers">>,ArchitectureMap),list_to_binary(MyRouter)), TODO remove


    %add this router to the graph G
    %digraph:add_vertex(G,MyRouter,{binary_to_list(HostName),getPort(maps:get(<<"routers">>,ArchitectureMap),list_to_binary(MyRouter))}),
    %io:format("~p~n",[{MyRouter,binary_to_list(HostName),getPort(maps:get(<<"routers">>,ArchitectureMap),list_to_binary(MyRouter))}]),


    [addtograph(G,ArchitectureMap,Entitie,binary_to_list(HostName)) || Entitie<-OnDeviceEntities ],
    G.

getAllHosts(ArchitectureMap) -> 
    [maps:get(<<"host">>,Device)|| Device <- maps:get(<<"devices">>,ArchitectureMap)].


%%connects all the routers in the network by the json configuration received in CommunicationMapAdderess
connectRouters(G,_ArchitectureMap,CommunicationMap) -> 

    ConnectionsMap = maps:to_list(maps:get(<<"connectionsMap">>,CommunicationMap)),
    [[addEdges(G,binary_to_list(Router),binary_to_list(Component))||Component<-Components]||{Router,Components}<-ConnectionsMap].
    % [[addEdges(G,binary_to_list(Router),binary_to_list(ListOfRouters))||ListOfRouters <- ListOfRouters]||{Router,ListOfRouters}<-ConnectionsMap].
    %io:format("ConnectionsMap:~n~p~n",[ConnectionsMap]).
	
addEdges(G,V1,V2) ->
  Edges = [digraph:edge(G,E) || E <- digraph:edges(G)],
  DupEdges = [E || {E, Vin, Vout, _Label} <- Edges, Vin == V1, Vout == V2],
  %io:format("DupEdges are: ~p~n",[DupEdges]),
  if length(DupEdges) /= 0 -> skip;
    true ->
      digraph:add_edge(G,V1,V2),
      digraph:add_edge(G,V2,V1)
  end.
	

%addtograph(G,ArchitectureMap,MyRouter,HostName) -> okPass;
addtograph(G,ArchitectureMap,Entitie,HostName) -> 
    io:format("~p~n",[{Entitie,HostName,getPortUnknown(ArchitectureMap,list_to_binary(Entitie))}]),
    digraph:add_vertex(G,Entitie,{HostName,getPortUnknown(ArchitectureMap,list_to_binary(Entitie))}).
    % addEdges(G,Entitie,MyRouter).
	
% getMyRouter(Routers,OnDeviceEntities) -> 
%     [Common] = [X || X <- Routers, Y <- OnDeviceEntities, X == Y],
%     Common.
