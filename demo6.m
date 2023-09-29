%% WIFI Project

%% 
% 1 AP + multiple users + IEEE 802.11 ax
% MAC 1024QAM (11), Bandwidth 80Mhz, Users: DataRateKps = 8e3

% Building Scenario
ScenarioParameters = struct;
ScenarioParameters.BuildingLayout = [3 1 1];
ScenarioParameters.RoomSize = [5 5 3];
simulationTime = 1000;

numUser = 160;
numAP = 1;
numNodes = numUser + numAP;
%addpath(genpath(fullfile(pwd, 'C:\Program Files\MATLAB\R2022b\examples\wlan\data\mlWLANSystemSimulation')));

load("wlanNodeConfig.mat");
nodeConfig = repmat(wlanNodeConfig,1,numNodes);

% AP Node
nodeConfig(1).IsAP = true;
nodeConfig(1).NodeName = "AP";
nodeConfig(1).NodePosition = [7.5 2.5 1.5];
nodeConfig(1).TxFormat = "HE_SU";
nodeConfig(1).Bandwidth = 80;
nodeConfig(1).TxMCS = 9;
MCSvalue = nodeConfig(1).TxMCS;
nodeConfig(1).TxNumSTS = 8;
nodeConfig(1).NumTxChains = 8;
nodeConfig(1).BandAndChannel = {[5, 42]}; % 5Ghz & 42 channel
nodeConfig(1).MaxDLStations = 1; %1 is for SU for MU it should be 8
%nodeConfig(1).RateControl = "ARF"; % About the transmission rate
nodeConfig(1).TxPower = 23;
nodeConfig(1).TxGain = 0; 

rng(1,"combRecursive");
for ind = 1:1:numNodes-1
    induser = ind + 1;
    nodeConfig(induser).NodeName = "User" + ind;    
    nodeConfig(induser).NodePosition = [15*rand(1), 5*rand(1), 3*rand(1)];
    nodeConfig(induser).TxFormat = "HE_SU";
    nodeConfig(induser).Bandwidth = 80;
    nodeConfig(induser).TxNumSTS = 8;
    nodeConfig(induser).NumTxChains = 8;
    nodeConfig(induser).BandAndChannel = {[5, 42]}; % 5Ghz & 42 channel
    %nodeConfig(induser).RateControl = "ARF";
    nodeConfig(induser).RxGain = 0; 
end

%% Traffic Configurations
load('wlanTrafficConfig.mat');
trafficConfig = repmat(wlanTrafficConfig, 1, numNodes-1);

for ind = 1:1:numNodes-1
    trafficConfig(ind).SourceNode = "AP";
    trafficConfig(ind).DestinationNode = "User" + ind;
    trafficConfig(ind).DataRateKbps = 8e3; % 8Mbps for Youtube, 25 Mbps for Netflix  
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
%hPlotStateTransition(visualizationInfo);

networkSimulator = hWirelessNetworkSimulator(wlanNodes);
%scheduleEvent(networkSimulator,@() pause(0.001),[],0,10);
run(networkSimulator,simulationTime);

%% Results
displayStatistics = 1;
statistics = getStatistics(statsLogger, displayStatistics);
filename1 = sprintf("%dUsers_MCS%d_statistics.mat",numUser,MCSvalue);
filename2 = sprintf("%dUsers_MCS%d_wlanNodes.mat",numUser,MCSvalue);
filename3 = sprintf("%dUsers_MCS%d_statistics.csv",numUser,MCSvalue);
save("C:\Users\pipim\OneDrive\Documents\WIFIProject\Results\WiFi6\Scenario1\SU\mat"+filename1,"statistics"); 
%save("C:\Users\pasch\OneDrive\WIFIProject/Results/WiFi6/Scenario1/SU/mat/"+filename2,"wlanNodes"); 
%%
hPlotNetworkStats(statistics,wlanNodes);
%%
writetable(statistics{1,1},"C:\Users\pipim\OneDrive\Documents\WIFIProject\Results\WiFi6\Scenario1\SU\csv"+filename3);

%% Test code to replot results 
% testData = load("C:\Users\pasch\OneDrive\WIFIProject/Results/WiFi6/Scenario1/SU/mat/5Users_MCS0_statistics.mat");
% testNodes = load("C:\Users\pasch\OneDrive\WIFIProject/Results/WiFi6/Scenario1/SU/mat/5Users_MCS0_wlanNodes.mat");
% hPlotNetworkStats(testData.statistics,testNodes.wlanNodes);