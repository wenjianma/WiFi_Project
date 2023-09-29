%% WiFi Project demo1
% Problem of demo1 -> this demo1 is based on
% WLANPHYFocusedSystemLevelSimulationExample.m
% The problem is about how to modify the apartment structure
% Still need more time to figure this code out
%% Scenario Description
% 1 AP + 1 user in each room
% 3 rooms apartment
% basic parameters
% indoor propogation model
%% Parameters
% Physical Layer -> the layer that we focus on 
PHYParameters = struct;
PHYParameters.TxPower = 20; 
PHYParameters.TxGain = 0;
PHYParameters.RxGain = -2;
PHYParameters.NoiseFigure = 7;
PHYParameters.NumTxAntennas = 1;
PHYParameters.NumRxAntennas = 1;
PHYParameters.ChannelBandwidth = 'CBW80';
PHYParameters.TransmitterFrequency = 5e9;

% MAC Layer -> not very important
MACParameters = struct;
MACParameters.NumChannels = 3;
MACParameters.CCALevel = -70;

% apartment 
ScenarioParameters = struct;
ScenarioParameters.BuildingLayout = [3 1 1]; % 3 rooms 
ScenarioParameters.RoomSize = [5 5 3]; % room size 5*5*3
ScenarioParameters.NumRxPerRoom = 1;

% control parameters
calibrate = true;
showScenarioPlot = true;
systemLevelSimulation = true;

%simulation parameters
SimParameters = struct;
SimParameters.NumDrops = 3;
SimParameters.NumTxEventsPerDrop = 2;
%% Body code

% Transmitter Sites
numTx = 1; % 1 AP
txs = txsite("cartesian",'TransmitterFrequency',PHYParameters.TransmitterFrequency, ...
    'TransmitterPower', 10.^((PHYParameters.TxPower+PHYParameters.TxGain-30)/10),...
    'Antenna','isotropic');

% Receiver Sites
numRx = 3;
roomNames = strings(1,numRx);
for siteInd = 1:numRx
    roomNames(siteInd) = "Room " + siteInd; 
end
rxs = rxsite("cartesian",'Name',roomNames,'Antenna','isotropic');

%Receiver nois power in dBm
T = 290; k = physconst("Boltzmann");
fs = wlanSampleRate(wlanHESUConfig("ChannelBandwidth",PHYParameters.ChannelBandwidth));
rxNoisePower = 10*log10(k*T*fs)+30+PHYParameters.NoiseFigure;


% SINR Calculation
seed = rng(6);

if showScenarioPlot
   hGrid = tgaxBuildResidentialGrid(ScenarioParameters.RoomSize, ScenarioParameters.BuildingLayout, ...
            numTx, numRx, MACParameters.NumChannels);
end

if calibrate
    fprintf("Running calibration ...\n")
end

output = struct;
output.sinr = zeros(SimParameters.NumDrops, numTx);
for drop = 1:SimParameters.NumDrops
    % Drop receivers in each room
    [associacltion, txChannels, rxChannels, txPositions, rxPositions] = tgaxDropNodes(...
    txs, rxs, ScenarioParameters, MACParameters.NumChannels);
    
    % All transmitters active
    activeTx = true(numTx,1);
    
    % Only pick one receiver per Room
    rxAlloc = randi([1 ScenarioParameters.NumRxPerRoom],numTx,1);
    activeRx = reshape(rxAlloc==1:ScenarioParameters.NumRxPerRoom,[],1);

    % Generate propagation model
    proModel = TGaxResidential("roomSize", ScenarioParameters.RoomSize);

    % Get the index of the transmitter for each receiver
    tnum = repmat((1:numTx),1,numRx/numTx);

    % SINR calculation 
    activeChannels = unique(txChannels);
    for k = 1:numel(activeChannels)
        tind = txChannels == activeChannels(k);
        rind = false(size(activeRx));
        rind(activeRx) = rxChannels(activeRx) == activeChannels(k);
        tsigind = tnum(rind);

        output.sinr(drop,tind) = sinr(rxs(rind),txs(rind), ...
         "ReceiverGain", PHYParameters.RxGain, ...
         "ReceiverNoisePower", rxNoisePower, ...
         "PropagationModel", proModel, ...
         "SignalSource", txs(tsigind));
    end

    if showScenarioPlot
        mask = txChannels == rxChannels';
        tgaxUpdatePlot(hGrid,txPositions,rxPositions,activeTx,activeRx,mask,txChannels,rxChannels, ...
        sprintf('Box 1 Test 2 "downlink only" calibration, drop #%d/%d',drop,SimParameters.NumDrops));
    end

    tgaxCalibrationCDF(output.sinr,'SS1Box1Test2','Long-term Radio Characteristics');

    fprintf('Calibration complete \n')
end









