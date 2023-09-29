%% WIFI Project
% This demo is based on demo2 &&"802.11ax Multinode System-Level Simulation of Residential Scenario Using MATLAB"

%% Simulation Scenario
% 3-room apartment
% 1 AP in this apartment and 1 STA in each room, 3 STAs in total
% AP locates in the center of this building, 3 STAs distribute randomly
% Protocol: IEEE 802.11 ac
% Specific parameters will be shown in next two sectors
rng(1,"combRecursive");
simulationTime = 100;  % 100 milliseconds
showLiveStateTransitionPlot = true;
displayStatistics = true;

%% Configure Simulation Parameters

% Scenario parameters
ScenarioParameters = struct;
ScenarioParameters.BuildingLayout = [3 1 1];
ScenarioParameters.RoomSize = [5 5 3];
ScenarioParameters.NumRxPerRoom = 1;

% 3 APs now, must disable other 2 APs
[apPositions, staPositions] = hDropNodes(ScenarioParameters);
[nodeConfigs, trafficConfigs] = hLoadConfiguration(ScenarioParameters,apPositions,staPositions);

%% Create AP & STA nodes
% nodeConfig 1 AP
% nodeConig 4 -> 6 STA 1->3 Enable all 

% WiFi 5  AP spatial streams = 4 Bandwidth = 80
% nodeConfigs(1).NodeName = 'AP';
nodeConfigs(1).NodePosition = [7.5 2.5 1.5]; 
nodeConfigs(1).TxFormat = "HE_SU";
nodeConfigs(1).BandAndChannel = {[5,16]}; 
nodeConfigs(1).Bandwidth = 80; 
nodeConfigs(1).MPDUAggregation = true;
nodeConfigs(1).NumTxChains = 4; 
nodeConfigs(1).TxNumSTS = 4; 
nodeConfigs(1).TxMCS = 0;  
nodeConfigs(1).DisableRTS = false; nodeConfigs(1).DisableAck = false;

% WiFi 5 STA spatial streams = 1 Bandwidth = 80
for staind = 4:1:6
    nodeConfigs(staind).TxFormat = "HE_SU";
    nodeConfigs(staind).BandAndChannel = {[5,16]}; 
    nodeConfigs(staind).Bandwidth = 80;
    nodeConfigs(staind).MPDUAggregation = true;
    nodeConfigs(staind).NumTxChains = 4;
    nodeConfigs(staind).TxNumSTS = 4;
    nodeConfigs(staind).TxMCS = 0;
    nodeConfigs(staind).DisableRTS = false; 
    nodeConfigs(staind).DisableAck = false;
end

%% Configure Traffic
for id = 2:1:3
    trafficConfigs(id).SourceNode = "Node1";
end

for id = 1:1:3
    trafficConfigs(id).DataRateKbps = 8e3;
    trafficConfigs(id).PacketSize = 100;
end

%% Create Network
[txs, rxs] = hCreateSitesFromNodes(nodeConfigs);
tri = hTGaxResidentialTriangulation(ScenarioParameters);
hVisualizeScenario(tri,txs,rxs,apPositions);
% This figure has some problem so far. Need to fix it later!

%propagation model
propModel = hTGaxResidentialPathLoss("Triangulation", tri, "ShadowSigma", 0, "FacesPerWall",1);
[pl,tgaxIndoorPLFn] = hCreatePathlossTable(txs,rxs,propModel);

wlanNodes = hCreateWLANNodes(nodeConfigs,trafficConfigs,"CustomPathLoss",tgaxIndoorPLFn,"MACFrameAbstraction", true, "PHYAbstractionType",'TGax Evaluation Methodology Appendix 1');

%% Simulation
visualizationInfo = struct;
visualizationInfo.Nodes = wlanNodes;
statsLogger = hWLANStatsLogger(visualizationInfo);

if showLiveStateTransitionPlot
    hPlotStateTransition(visualizationInfo);
end

networkSimulator = hWirelessNetworkSimulator(wlanNodes);
scheduleEvent(networkSimulator,@() pause(0.001),[],0,10);
run(networkSimulator,simulationTime);

%% Results
statistics = getStatistics(statsLogger, displayStatistics);
save("statistics.mat","statistics"); 
%statistics.mat includes all info about this simulation, findout the
%features we want to explore!!!!
hPlotNetworkStats(statistics,wlanNodes);
%hPlotStateTransition(statistics);
