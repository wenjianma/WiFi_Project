%% WIFI Project
%% WIFI 5
%% 
% 1 AP + multiple users + IEEE 802.11 ac

% Building Scenario
ScenarioParameters = struct;
ScenarioParameters.BuildingLayout = [3 1 1];
ScenarioParameters.RoomSize = [5 5 3];
simulationTime = 1000;

numUser = 20;
numAP = 1;
numNodes = numUser + numAP;

load("wlanNodeConfig.mat");
nodeConfig = repmat(wlanNodeConfig,1,numNodes);

% AP Node
nodeConfig(1).IsAP = true;
nodeConfig(1).NodeName = "AP";
nodeConfig(1).NodePosition = [12.5 2.5 1.5];
nodeConfig(1).TxFormat = "VHT";
nodeConfig(1).Bandwidth = 80;
nodeConfig(1).TxMCS = 7;
nodeConfig(1).TxNumSTS = 4;
nodeConfig(1).NumTxChains = 4;
nodeConfig(1).BandAndChannel = {[5, 42]}; % 5Ghz & 42 channel
nodeConfig(1).MaxDLStations = 1;
%nodeConfig(1).RateControl = "ARF"; % About the transmission rate
nodeConfig(1).TxPower = 23;

rng(1,"combRecursive");
for ind = 1:1:numNodes-1
    induser = ind + 1;
    nodeConfig(induser).NodeName = "User" + ind;    
    nodeConfig(induser).NodePosition = [5*rand(1), 5*rand(1), 3*rand(1)];
    nodeConfig(induser).TxFormat = "VHT";
    nodeConfig(induser).Bandwidth = 80;
    nodeConfig(induser).TxNumSTS = 4;
    nodeConfig(induser).NumTxChains = 4;
    nodeConfig(induser).BandAndChannel = {[5, 42]}; % 5Ghz & 42 channel
    %nodeConfig(1).RateControl = "ARF";
end

%% Traffic Configurations
load('wlanTrafficConfig.mat');
trafficConfig = repmat(wlanTrafficConfig, 1, numNodes-1);

for ind = 1:1:numNodes-1
    trafficConfig(ind).SourceNode = "AP";
    trafficConfig(ind).DestinationNode = "User" + ind;
    trafficConfig(ind).DataRateKbps = 8e3; % 8Mbps 
end

%% Create Network
[txs,rxs] = hCreateSitesFromNodes(nodeConfig);
tri = hTGaxResidentialTriangulation(ScenarioParameters);
hVisualizeScenario(tri,txs,rxs,nodeConfig(1).NodePosition);

%prop model
propModel = hTGaxResidentialPathLoss("Triangulation", tri, "ShadowSigma", 0, "FacesPerWall",1);
[pl,tgaxIndoorPLFn] = hCreatePathlossTable(txs,rxs,propModel);
wlanNodes = hCreateWLANNodes(nodeConfig,trafficConfig,"CustomPathLoss",tgaxIndoorPLFn,"MACFrameAbstraction", true, "PHYAbstractionType",'TGax Evaluation Methodology Appendix 1');

%% Simulation
visualizationInfo = struct;
visualizationInfo.Nodes = wlanNodes;
statsLogger = hWLANStatsLogger(visualizationInfo);
hPlotStateTransition(visualizationInfo);

networkSimulator = hWirelessNetworkSimulator(wlanNodes);
%scheduleEvent(networkSimulator,@() pause(0.001),[],0,10);
run(networkSimulator,simulationTime);

%% Results
displayStatistics = 1;
statistics = getStatistics(statsLogger, displayStatistics);
save("statistics.mat","statistics"); 
save("C:\Users\pipim\OneDrive\Documents\WIFIProject\Results\WiFi5\Scenario2\mat\20Users_MCS7_statistics","statistics"); 
%save("C:\Users\pipim\OneDrive\Documents\WIFIProject\Results\WiFi5\Scenario1\mat\5Users_MCS0_wlanNodes.mat","wlanNodes"); 
hPlotNetworkStats(statistics,wlanNodes);
writetable(statistics{1,1},"C:\Users\pipim\OneDrive\Documents\WIFIProject\Results\WiFi5\Scenario2\csv\20Users_MCS7_statistics.csv");