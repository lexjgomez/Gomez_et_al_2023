%% Firing Rate during Movement and Non-Movement Periods

clearvars -except Database
count8 = 1; count12 = 1; 
for k = 1:length(Database)
    age = Database(k).age;
    if age < 10
        lxmsP8(count8) = Database(k);
        count8 = count8 +1; 
    else 
        lxmsP12(count12) = Database(k); 
        count12 = count12+1;
    end 
end 
clear count8 count12 k age; 

thisDB = lxmsP8;
%first, get your movement/no movement times

for k = 1:length(thisDB)
    curCase = thisDB(k);
    curValueSeries = curCase.movement.values;
    curTimeSeries = curCase.movement.times;
    %extract logical of movement periods
    cmvmt = Movement_Periods(curValueSeries);
    
    %get the times of movement/non-movement periods
    getfirst = cmvmt(1); getChange = diff([0;cmvmt]);
    onTimes = []; offTimes = [];
    for kk = 1:length(getChange)
        cChange = getChange(kk);
        if cChange > 0 %this marks your transition into a movement period
            onTimes = [onTimes curTimeSeries(kk)];
        elseif cChange < 0 %this marks your transition into a non-movement period
            offTimes = [offTimes curTimeSeries(kk)];
        end 
    end 
    
    %you need to make sure that your on and off times are the same length
    %and that On times starts first (ignores if you start during movement)
    isEqualLength = length(onTimes) == length(offTimes);
    firstOn = onTimes(1); firstOff = offTimes(1); 
    onOffOrder = firstOn < firstOff;
    
    %first get the order of OnOff
    if onOffOrder == 1 %on times are first
        if isEqualLength == 1 %and they are of equal length
            OnOffTimes = [onTimes.' offTimes.'];
        else %if they are unequal, you end on an on time
            OnOffTimes = [onTimes(1:end-1).' offTimes.'];
        end
    else %off times are first
        if isEqualLength == 1 %if they are equal
            OnOffTimes = [onTimes(1:end-1).' offTimes(2:end).']; %ignore the first off Time
        else %if they are unequal, you end on an off time
            OnOffTimes = [onTimes.' offTimes(2:end).'];
        end
    end
    
    thisDB(k).movement(1).type = 'Movement';
    thisDB(k).movement(1).times = OnOffTimes;
    
    %then get the order of Off On
    if onOffOrder == 1 %on times are first
        if isEqualLength == 1 %and they are of equal length
            OffOnTimes = [offTimes(1:end-1).' onTimes(2:end).'];
        else %if they are unequal
            OffOnTimes = [offTimes.' onTimes(2:end).'];
        end
    else %off times are first
        if isEqualLength == 1 %if they are equal
            OffOnTimes = [offTimes.' onTimes.']; 
        else %if they are unequal
            OffOnTimes = [offTimes(1:end-1).' onTimes.'];
        end
    end
    
    thisDB(k).movement(2).type = 'NoMovement';
    thisDB(k).movement(2).times = OffOnTimes;    
end 

%% Determine Movement/No Movement during different behavioral states (AS and W)
% this is an abomination of for loops
%for each behavioral state, look for periods of movement vs. no movement
numStates = 2;
numMoves = 2; 
thisDBM = thisDB;

for e = 1:length(thisDB)
    curCase = thisDB(e);
    cranges = curCase.ranges;
    cmoves = curCase.movement;
    count = 1;%this is for indexing into the DB
    for ee = 1:numStates %for each state
        curState = cranges(ee).nTimes;
        curStateName = cranges(ee).type;
        for eee = 1:numMoves %for each movement times
            curMoves = cmoves(eee).times;
            curMoveName = cmoves(eee).type; 
            
            StateAndMove = append(curStateName,curMoveName);
            
            csmv = [];
            %going through the time periods for each state 
            [rl,cl] = size(curState);
            for eeee = 1:rl
                curRange = curState(eeee,:);
                
                for rr = 1:length(curMoves)
                    cmr = curMoves(rr,:);
                    if cmr(1) >= curRange(1)
                        if cmr(2) <= curRange(2)
                            csmv = [csmv; cmr];
                        end 
                    end         
                end 
            end
            
            thisDBM(e).StateMove(count).type = StateAndMove;
            thisDBM(e).StateMove(count).nTimes = csmv;
            count = count +1;
        end 
    end 
end 


%% Get the firing rate during Movement/Non-Movement Periods
clearvars -except Database thisDB thisDBM
fr1_ASM = [];
fr1_ASNM = [];
fr1_AWM = [];
fr1_AWNM = [];

fr2_ASM = [];
fr2_ASNM = [];
fr2_AWM = [];
fr2_AWNM = [];

for g = 1:length(thisDBM)
    curCase = thisDBM(g);
    StateMove = curCase.StateMove; 
    Neurons1 = curCase.Neurons1;
    Neurons2 = curCase.Neurons2;
    
    getRanges = 4;
    cranges(1).type = StateMove(1).type; cranges(1).nTimes = StateMove(1).nTimes;
    cranges(2).type = StateMove(2).type; cranges(2).nTimes = StateMove(2).nTimes;
    cranges(3).type = StateMove(3).type; cranges(3).nTimes = StateMove(3).nTimes;
    cranges(4).type = StateMove(4).type; cranges(4).nTimes = StateMove(4).nTimes;

    [fRates1] = FiringRates(Neurons1, cranges, getRanges); 
    [fRates2] = FiringRates(Neurons2, cranges, getRanges); 

    asMoves1 = []; asNoMoves1 = [];
    wMoves1 = []; wNoMoves1 = [];
    for gg = 1:length(fRates1)
        asMoves1 = [asMoves1 fRates1(gg).ActiveSleepMovement];
        asNoMoves1 = [asNoMoves1 fRates1(gg).ActiveSleepNoMovement];
        wMoves1 = [wMoves1 fRates1(gg).ActiveWakeMovement];
        wNoMoves1 = [wNoMoves1 fRates1(gg).ActiveWakeNoMovement];
    end 

    fr1_ASM = [fr1_ASM mean(asMoves1)];
    fr1_ASNM = [fr1_ASNM mean(asNoMoves1)];
    fr1_AWM = [fr1_AWM mean(wMoves1)];
    fr1_AWNM = [fr1_AWNM mean(wNoMoves1)];    
    
    
    asMoves2 = []; asNoMoves2 = [];
    wMoves2 = []; wNoMoves2 = [];
    for ggg = 1:length(fRates2)
        asMoves2 = [asMoves2 fRates2(ggg).ActiveSleepMovement];
        asNoMoves2 = [asNoMoves2 fRates2(ggg).ActiveSleepNoMovement];
        wMoves2 = [wMoves2 fRates2(ggg).ActiveWakeMovement];
        wNoMoves2 = [wNoMoves2 fRates2(ggg).ActiveWakeNoMovement];
    end     
    
    fr2_ASM = [fr2_ASM mean(asMoves2)];
    fr2_ASNM = [fr2_ASNM mean(asNoMoves2)];
    fr2_AWM = [fr2_AWM mean(wMoves2)];
    fr2_AWNM = [fr2_AWNM mean(wNoMoves2)];
   
end 

Moves1 = [fr1_ASM.' fr1_ASNM.' fr1_AWM.' fr1_AWNM.'];
Moves2 = [fr2_ASM.' fr2_ASNM.' fr2_AWM.' fr2_AWNM.'];

Move1Means = mean(Moves1); 
Move2Means = mean(Moves2); 

SEM1Move = std(Moves1,1)./sqrt(size(Moves1,1));
SEM2Move = std(Moves2,1)./sqrt(size(Moves2,1));

figure
subplot(1,2,1)
bar(Move1Means)
hold on
er = errorbar(Move1Means, SEM1Move);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
[n,m] = size(Moves1); 
for mm = 1:m
    [xData, yData] = Scatter_Jitter(mm, Moves1(:,mm));
    scatter(xData, yData)
end 
xticks([1 2 3 4])
xticklabels({'AS_M','AS_No', 'W_M', 'W_No'})
ylim([0 10])
xlim([0 5])
title('Neurons1')

subplot(1,2,2)
bar(Move2Means)
hold on
er = errorbar(Move2Means, SEM2Move);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
[n,m] = size(Moves2); 
for mm = 1:m
    [xData, yData] = Scatter_Jitter(mm, Moves2(:,mm));
    scatter(xData, yData)
end 
xticks([1 2 3 4])
xticklabels({'AS_M','AS_No', 'W_M', 'W_No'})
ylim([0 10])
xlim([0 5])
title('Neurons2')

a= 0;
[h,p] = ttest(a(:,1),a(:,2))
[h,p] = ttest(a(:,3),a(:,4))
