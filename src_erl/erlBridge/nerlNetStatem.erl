%%%-------------------------------------------------------------------
%%% @author ziv
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Oct 2020 21:58
%%%-------------------------------------------------------------------
-module(nerlNetStatem).
-author("ziv").
-include("cppSANNStatemModes.hrl").

-behaviour(gen_statem).

%% API
-export([start_link/1]).

%% gen_statem callbacks
-export([init/1, format_status/2, state_name/3, handle_event/4, terminate/3,
  code_change/4, callback_mode/0]).
%% States functions
-export([idle/3, train/3, predict/3, wait/3]).

-define(SERVER, ?MODULE).

%% federatedMode = 0 - Not federated, 1 - Federated get and send weights, 2 - Federated set weights
%% countLimit - Number of samples to count before sending the weights for averaging. Predifined in the json file.
%% count - Number of samples recieved for training after the last weights sended.
-record(nerlNetStatem_state, {clientPid, features, labels, myName, modelId, nextState, missedSamplesCount = 0, missedTrainSamples= [], federatedMode, count = 1, countLimit}).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Creates a gen_statem process which calls Module:init/1 to
%% initialize. To ensure a synchronized start-up procedure, this
%% function does not return until Module:init/1 has returned.
start_link(ARGS) ->
  %{ok,Pid} = gen_statem:start_link({local, ?SERVER}, ?MODULE, [], []),
  {ok,Pid} = gen_statem:start_link(?MODULE, ARGS, []),
  Pid.

%%%===================================================================
%%% gen_statem callbacks
%%%===================================================================

%% @private
%% @doc Whenever a gen_statem is started using gen_statem:start/[3,4] or
%% gen_statem:start_link/[3,4], this function is called by the new
%% process to initialize.
init({ClientPID, MyName, {Layers_sizes, Learning_rate, ActivationList, Optimizer, ModelId, Features, Labels, FederatedMode, CountLimit}}) ->
%init({ClientPID, MyName, {Layers_sizes, Learning_rate, ActivationList, Optimizer, ModelId, Features, Labels}}) ->
 % FederatedMode = 0, % TODO delete
%  CountLimit = 1, % TODO delete
  io:fwrite("start module_create ~n"),

  _Res=erlModule:module_create(Layers_sizes, Learning_rate, ActivationList, Optimizer, ModelId),
  io:fwrite("Layers_sizes: ~p, Learning_rate: ~p, ActivationList: ~p, Optimizer: ~p, ModelId ~p\n",[Layers_sizes, Learning_rate, ActivationList, Optimizer, ModelId]),
  %io:fwrite("Mid: ~p\n",[Mid]),
  %{ok, idle, []}.
  %timer:sleep(20000),
  %Ret_weights_tuple = erlModule:get_weights(0),
  %{Wheights,Bias,Biases_sizes_list,Wheights_sizes_list} = Ret_weights_tuple,
  %ListToSend = Wheights ++ ["$"]  ++ Bias ++ ["$"]  ++ Biases_sizes_list ++ ["$"]  ++ Wheights_sizes_list,
  %io:fwrite("ListToSend: ~p\n",[ListToSend]),
  %file:write_file("NerlStatemOut.txt", [lists:flatten(io_lib:format("~p~p~p~p",[Bias,Wheights,Biases_sizes_list,Wheights_sizes_list]))]),
  %timer:sleep(20000),
 % erlModule:set_weights(["-0.3","-0.486040","0.306024","-0.480839","0.014879","0.333101","0.015029","-0.235519","0.206851","0.089756","-0.086243","-0.5"], Bias, Biases_sizes_list,Wheights_sizes_list, 0),

  % timer:sleep(20000),
  %Ret_weights_tuple1 = erlModule:get_weights(0),
  %{Wheights1,Bias1,Biases_sizes_list1,Wheights_sizes_list1} = Ret_weights_tuple1,

  %L1 = decode1("1@2@3%1@4@5"),
  %io:fwrite("L1: ~p\n",[L1]),
  %L1 = encodeList(["1","2","3","4"]),
  %L2 = encodeList(["5","6"]),
  %List2Send = L1++"%"++L2,
  %io:fwrite("List2Send: ~p\n",[List2Send]),
  %[L3,L4] = decode1(List2Send),
  %L5 = decode(L3),
  %L6 = decode(L4),
  %io:fwrite("L5: ~p\n",[L5]),
  %io:fwrite("L6: ~p\n",[L6]),

  %file:write_file("NerlStatemOutAfterSet.txt", [lists:flatten(io_lib:format("~p~p~p~p",[Bias1,Wheights1,Biases_sizes_list1,Wheights_sizes_list1]))]),
  %Ret_average_list = erlModule:average_weights([1,1,1,1,1,9,8,0,1,2,1,2],3),
  %{AverageWeightsAndBiases,NumOfWeightsAndBiasesLists} = Ret_average_list,
  %io:fwrite("AverageWeightsAndBiases: ~p\n",[AverageWeightsAndBiases]),
  %io:fwrite("NumOfWeightsAndBiasesLists: ~p\n",[NumOfWeightsAndBiasesLists]),

  %file:write_file("NerlStatemOutAverage.txt", [lists:flatten(io_lib:format("~p~p",[AverageWeightsAndBiases,NumOfWeightsAndBiasesLists]))]),

  {ok, idle, #nerlNetStatem_state{clientPid = ClientPID, features = Features, labels = Labels, myName = MyName, modelId = ModelId, federatedMode = FederatedMode, countLimit = CountLimit}}.

%% @private
%% @doc This function is called by a gen_statem when it needs to find out
%% the callback mode of the callback module.
callback_mode() ->
  state_functions.

%% @private
%% @doc Called (1) whenever sys:get_status/1,2 is called by gen_statem or
%% (2) when gen_statem terminates abnormally.
%% This callback is optional.
format_status(_Opt, [_PDict, _StateName, _State]) ->
  Status = some_term,
  Status.

%% @private
%% @doc There should be one instance of this function for each possible
%% state name.  If callback_mode is state_functions, one of these
%% functions is called when gen_statem receives and event from
%% call/2, cast/2, or as a normal process message.
state_name(_EventType, _EventContent, State = #nerlNetStatem_state{}) ->
  NextStateName = next_state,
  {next_state, NextStateName, State}.

%% @private
%% @doc If callback_mode is handle_event_function, then whenever a
%% gen_statem receives an event from call/2, cast/2, or as a normal
%% process message, this function is called.
handle_event(_EventType, _EventContent, _StateName, State = #nerlNetStatem_state{}) ->
  NextStateName = the_next_state_name,
  {next_state, NextStateName, State}.

%% @private
%% @doc This function is called by a gen_statem when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_statem terminates with
%% Reason. The return value is ignored.
terminate(_Reason, _StateName, _State) ->
  ok.

%% @private
%% @doc Convert process state when code is changed
code_change(_OldVsn, StateName, State = #nerlNetStatem_state{}, _Extra) ->
  {ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%% Define states

%% State idle
idle(cast, {training}, State = #nerlNetStatem_state{}) ->
  io:fwrite("Go from idle to train\n"),
  {next_state, train, State};

idle(cast, {predict}, State) ->
  io:fwrite("Go from idle to predict\n"),
  {next_state, predict, State};

idle(cast, {set_weights,Ret_weights_tuple}, State = #nerlNetStatem_state{nextState = NextState, modelId=ModelId}) ->

  io:fwrite("Set weights in wait state: \n"),
  
  %% Set weights TODO maybe send the results of the update
  {WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist} = decodeTuple(Ret_weights_tuple),
  % io:fwrite("WeightsStringList: ~p BiasStringList: ~p Biases_sizes_Stringlist: ~p Wheights_sizes_Stringlist: ~p\n",[WeightsStringList,BiasStringList,Biases_sizes_Stringlist,Wheights_sizes_Stringlist]),
  _Result_set_weights = erlModule:set_weights(WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist, ModelId),

  {next_state, NextState, State};

idle(cast, Param, State) ->
  io:fwrite("Same state idle, command: ~p\n",[Param]),
  {next_state, idle, State}.

%% Waiting for receiving results or loss function
%% Got nan or inf from loss function - Error, loss function too big for double
wait(cast, {loss,nan,_Time_NIF}, State = #nerlNetStatem_state{clientPid = ClientPid, myName = MyName, nextState = NextState}) ->
  io:fwrite("ERROR: Loss func in wait: nan (Loss function too big for double)\n"),
  gen_statem:cast(ClientPid,{loss, MyName, nan}), %% TODO send to tal stop casting request with error desc
  {next_state, NextState, State};

wait(cast, {loss, LossAndTime,Time_NIF}, State = #nerlNetStatem_state{clientPid = ClientPid, myName = MyName, nextState = NextState, count = Count, countLimit = CountLimit, modelId = Mid, federatedMode = FederatedMode}) ->
  {LOSS_FUNC,TimeCpp} = LossAndTime,
  io:format("Count:~p~n",[Count]),
  %io:format("CountLimit:~p~n",[CountLimit]),

  % io:fwrite("Loss func in wait: ~p\nTime for train execution in cppSANN (micro sec): ~p\nTime for train execution in NIF+cppSANN (micro sec): ~p\n",[LOSS_FUNC, TimeCpp, Time_NIF]),
  if Count == CountLimit ->
%%    (Count == CountLimit) and FederatedMode == ?MODE_FEDERATED ->
      % Get weights
      io:fwrite("Get weights: \n"),
      Ret_weights_tuple = erlModule:get_weights(Mid),
      {Wheights,Bias,Biases_sizes_list,Wheights_sizes_list} = Ret_weights_tuple,
      % io:fwrite("Wheights: ~p,Bias: ~p,Biases_sizes_list: ~p,Wheights_sizes_list: ~p \n",[Wheights,Bias,Biases_sizes_list,Wheights_sizes_list]),
      
      L1 = encodeList(Wheights),
       io:fwrite(" L1: ~p\n",[L1]),
      L2 = encodeList(Bias),
      % io:fwrite(" L2: ~p\n",[L2]),
      L3 = encodeList(Biases_sizes_list),
      io:fwrite(" L3: ~p\n",[L3]),
      L4 = encodeList(Wheights_sizes_list),
      io:fwrite(" L4: ~p\n",[L4]),
      ListToSend = L1++"%"++L2++"%"++L3++"%"++L4,
      % io:fwrite("nerlNerStatem: Federated, Count == CountLimit, Count: ~p Wheights: ~p, Bias: ~p, Biases_sizes_list: ~p, Wheights_sizes_list: ~p, List2Send: ~p\n",[Count, Wheights, Bias, Biases_sizes_list, Wheights_sizes_list, ListToSend]),
      % io:fwrite("nerlNerStatem: Count == CountLimit, Count ~p: CountLimit: ~p, LOSS_FUNC: ~p\n",[Count, CountLimit, LOSS_FUNC]),

      %file:write_file("NerlStatemOut.txt", [lists:flatten(io_lib:format("~p~p~p",[Size,Bias,Wheights]))]), %  TODO delete, for debugging

      % Send weights and loss value TODO
      gen_statem:cast(ClientPid,{loss, federated_weights, MyName, LOSS_FUNC, ListToSend}), %% TODO Add Time and Time_NIF to the cast
      
      % Reset count and go to state train
      {next_state, NextState, State#nerlNetStatem_state{count = 1}};

    FederatedMode == ?MODE_FEDERATED ->
      %% Send back the loss value
      io:fwrite("nerlNerStatem: Count < CountLimit, Count ~p: CountLimit: ~p, LOSS_FUNC: ~p\n",[Count, CountLimit, LOSS_FUNC]),
      gen_statem:cast(ClientPid,{loss, MyName, LOSS_FUNC}), %% TODO Add Time and Time_NIF to the cast
      {next_state, NextState, State#nerlNetStatem_state{count = Count + 1}};

    true -> % Federated mode = 0 (not federated)
      % io:fwrite("NOT Federated wait: \n"),
       io:fwrite("loss statem: ~p\n", [LOSS_FUNC]),
      gen_statem:cast(ClientPid,{loss, MyName, LOSS_FUNC}), %% TODO Add Time and Time_NIF to the cast
      {next_state, NextState, State}
  end;

wait(cast, {set_weights,Ret_weights_tuple}, State = #nerlNetStatem_state{nextState = NextState, modelId=ModelId}) ->
  io:fwrite("Set weights in wait state: \n"),

  %% Set weights TODO
  {WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist} = decodeTuple(Ret_weights_tuple),
  % io:fwrite("WeightsStringList: ~p BiasStringList: ~p Biases_sizes_Stringlist: ~p Wheights_sizes_Stringlist: ~p\n",[WeightsStringList,BiasStringList,Biases_sizes_Stringlist,Wheights_sizes_Stringlist]),
  _Result_set_weights = erlModule:set_weights(WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist, ModelId),

  {next_state, NextState, State};

%wait(cast, {loss,LossAndTime,Time_NIF}, State = #nerlNetStatem_state{clientPid = ClientPid, myName = MyName, nextState = NextState}) ->

  %{LOSS_FUNC,TimeCpp} = LossAndTime,
  %io:fwrite("Loss func in wait: ~p\nTime for train execution in cppSANN (micro sec): ~p\nTime for train execution in NIF+cppSANN (micro sec): ~p\n",[LOSS_FUNC, TimeCpp, Time_NIF]),
 % gen_statem:cast(ClientPid,{loss, MyName, LOSS_FUNC}), %% TODO Add Time and Time_NIF to the cast
%  {next_state, NextState, State};

wait(cast, {predictRes,CSVname, BatchID, {RESULTS,TimeCpp},Time_NIF}, State = #nerlNetStatem_state{clientPid = ClientPid, nextState = NextState}) ->
  % io:fwrite("Predict results: ~p\nTime for predict execution in cppSANN (micro sec): ~p\nTime for predict execution in NIF+cppSANN (micro sec): ~p\n",[RESULTS, TimeCpp, Time_NIF]),
  gen_statem:cast(ClientPid,{predictRes, CSVname, BatchID, RESULTS}), %% TODO Add Time and Time_NIF to the cast
  {next_state, NextState, State};

wait(cast, {idle}, State) ->
  io:fwrite("Waiting, next state - idle: \n"),
  {next_state, wait, State#nerlNetStatem_state{nextState = idle}};

wait(cast, {training}, State) ->
  io:fwrite("Waiting, next state - train: \n"),
  {next_state, wait, State#nerlNetStatem_state{nextState = train}};

wait(cast, {predict}, State) ->
  io:fwrite("Waiting, next state - predict: \n"),
  {next_state, wait, State#nerlNetStatem_state{nextState = predict}};

wait(cast, {sample, SampleListTrain}, State = #nerlNetStatem_state{missedSamplesCount = MissedSamplesCount, missedTrainSamples = MissedTrainSamples}) ->
  io:fwrite("Missed, got sample. Got: ~p \n Missed batches count: ~p\n",[{SampleListTrain}, MissedSamplesCount]),
  io:fwrite("Missed in pid: ~p, Missed batches count: ~p\n",[self(), MissedSamplesCount]),
  Miss = MissedTrainSamples++SampleListTrain,
  {next_state, wait, State#nerlNetStatem_state{missedSamplesCount = MissedSamplesCount+1, missedTrainSamples = Miss}};

wait(cast, Param, State) ->
  io:fwrite("Not supposed to be. Got: ~p\n",[{Param}]),
  {next_state, wait, State}.


%% State train
train(cast, {sample, SampleListTrain}, State = #nerlNetStatem_state{modelId = ModelId, features = Features, labels = Labels, myName = MyName}) ->
  CurrPid = self(),
  ChunkSizeTrain = round(length(SampleListTrain)/(Features + Labels)),
  %io:fwrite("length(SampleListTrain)/(Features + Labels): ~p\n",[length(SampleListTrain)/(Features + Labels)]),
  % io:fwrite("Send sample to train: ~p\n",[SampleListTrain]),
  % io:fwrite("ChunkSizeTrain: ~p, Features: ~p Labels: ~p ModelId ~p\n",[ChunkSizeTrain, Features, Labels, ModelId]),
  io:fwrite("Train state: got sample, pid: ~p\n", [CurrPid]),
  
  % file:write_file("NerlStatemOutTrain.txt", [lists:flatten(io_lib:format("ChunkSizeTrain: ~p Features: ~p Labels: ~p ModelId: ~p CurrPid: ~p MyName: ~p /n SampleListTrain: ~p /n",
  % [ChunkSizeTrain,Features,Labels,ModelId,CurrPid,MyName,SampleListTrain]))],[append]),

  _Pid = spawn(fun()-> erlModule:train2double(ChunkSizeTrain, Features, Labels, SampleListTrain,ModelId,CurrPid) end),
  {next_state, wait, State#nerlNetStatem_state{nextState = train}};


train(cast, {set_weights,Ret_weights_tuple}, State = #nerlNetStatem_state{modelId = ModelId, nextState = NextState}) ->

  % io:fwrite("nerlNetStatem: Set weights in train state: \n"),

  % Get_weights_tuple = erlModule:get_weights(ModelId),
  % io:fwrite("Get weights before set: ~p~n",[Get_weights_tuple]),

  %% Set weights TODO
  {WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist} = decodeTuple(Ret_weights_tuple),
   io:fwrite("nerlNetStatem: Set weights in train state: WeightsStringList: ~p BiasStringList: ~p Biases_sizes_Stringlist: ~p Wheights_sizes_Stringlist: ~p\n",[WeightsStringList,BiasStringList,Biases_sizes_Stringlist,Wheights_sizes_Stringlist]),
  _Result_set_weights = erlModule:set_weights(WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist, ModelId),

  % Get_weights_tuple1 = erlModule:get_weights(ModelId),
  % io:fwrite("Get weights after set: ~p~n",[Get_weights_tuple1]),

  {next_state, NextState, State};


%train(cast, {idle}, State = #nerlNetStatem_state{missedTrainSamples = MissedTrainSamples,modelId = ModelId, features = Features, labels = Labels}) ->
%  io:fwrite("Go from train to idle after finishing Missed train samples: ~p\n",[MissedTrainSamples]),
  %trainMissed(MissedTrainSamples,ModelId,Features,Labels),
%  io:fwrite("Go from train to idle\n"),
%  {next_state, idle, State};

train(cast, {idle}, State) ->
  %io:fwrite("Go from train to idle after finishing Missed train samples: ~p\n",[MissedTrainSamples]),
  %trainMissed(MissedTrainSamples,ModelId,Features,Labels),
  io:fwrite("Go from train to idle\n"),
  {next_state, idle, State};

train(cast, {predict}, State) ->
  io:fwrite("Go from train to predict\n"),
  {next_state, predict, State};

train(cast, Param, State) ->
  io:fwrite("Same state train, not supposed to be, command: ~p\n",[Param]),
  {next_state, train, State}.

trainMissed([],ModelId,Features,Labels)->
  io:fwrite("Finished train samples\n");

trainMissed([FirstTrainChunk|MissedTrainSamples],ModelId,Features,Labels)->
  CurrPid = self(),
  ChunkSizeTrain = round(length(FirstTrainChunk)/(Features + Labels)),
  _Pid = spawn(fun()-> erlModule:train2double(ChunkSizeTrain, Features, Labels, FirstTrainChunk,ModelId,CurrPid) end),
  trainMissed([FirstTrainChunk|MissedTrainSamples],ModelId,Features,Labels).

%% State predict
predict(cast, {sample,CSVname, BatchID, SampleListPredict}, State = #nerlNetStatem_state{features = Features, modelId = ModelId}) ->
  ChunkSizePred = round(length(SampleListPredict)/Features),
  CurrPID = self(),
  %io:fwrite("length(SampleListPredict)/Features): ~p\n",[length(SampleListPredict)/Features]),
  % io:fwrite("Send sample to predict\n"),
  _Pid = spawn(fun()-> erlModule:predict2double(SampleListPredict,ChunkSizePred,Features,ModelId,CurrPID, CSVname, BatchID) end),
  {next_state, wait, State#nerlNetStatem_state{nextState = predict}};

predict(cast, {idle}, State) ->
  io:fwrite("Go from predict to idle\n"),
  {next_state, idle, State};

predict(cast, {training}, State) ->
  io:fwrite("Go from predict to train\n"),
  {next_state, train, State};

predict(cast, Param, State) ->
  io:fwrite("Same state Predict, command: ~p\n",[Param]),
  {next_state, predict, State}.



encode(Ret_weights_tuple)->
  {Wheights,Bias,Biases_sizes_list,Wheights_sizes_list} = Ret_weights_tuple,
  Wheights ++ [a] ++ Bias ++ [a] ++ Biases_sizes_list ++ [a] ++ Wheights_sizes_list.

encode1(Ret_weights_tuple)->
  {Weights,Bias,Biases_sizes_list,Wheights_sizes_list} = Ret_weights_tuple,
  ToSend = list_to_binary(Weights) ++ <<"@">> ++ list_to_binary(Bias) ++ <<"@">> ++ list_to_binary(Biases_sizes_list) ++ <<"@">>  ++ list_to_binary(Wheights_sizes_list),
  % io:format("ToSend  ~p",[ToSend]),
    ToSend.

decode(L) -> re:split(L, "@", [{return, list}]).
decode1(L) -> re:split(L, "%", [{return, list}]).

encodeList(L)->
% io:fwrite("L: ~p~n",[L]),
% file:write_file("encodeList.txt", [lists:flatten(io_lib:format("~p",[L]))]),
[_H|T] = encodeList(L,[]), T.
encodeList([],L) -> L;
encodeList([H|T],L)->
  % io:fwrite("L: ~p~n",[L]),
  encodeList(T,L++"@"++H).

decodeTuple(Ret_weights_tuple1) ->
  [WeightsStringList1, BiasStringList1, Biases_sizes_Stringlist1, Wheights_sizes_Stringlist1] = decode1(Ret_weights_tuple1),
  WeightsStringList = decode(WeightsStringList1),
  BiasStringList = decode(BiasStringList1),
  Biases_sizes_Stringlist = decode(Biases_sizes_Stringlist1),
  Wheights_sizes_Stringlist = decode(Wheights_sizes_Stringlist1),
  {WeightsStringList, BiasStringList, Biases_sizes_Stringlist, Wheights_sizes_Stringlist}.