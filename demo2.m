%% WIFI Project
% This demo2 is based on " Get Started with WLAN System-Level Simulation in
% MATLAB" 
%% Simulation Scenario
% 1 AP + 1 user 
% IEEE802.11 ac 
%% Configure Simulation Parameters
rng(1,"combRecursive");
simulationTime = 1000;  % 1000 milliseconds
showLiveStateTransitionPlot = true;
displayStatistics = true;

%% Create AP & STA nodes
% nodes & locations 
numNodes = 2;
nodePostions = [10,0,0;20,0,0];
apNodeName = 'AP';
staNodeName = 'STA';

load("wlanNodeConfig.mat");
nodeConfig = repmat(wlanNodeConfig,1,numNodes);

% WIFI 5 AP node configuration
nodeConfig(1).NodeName = apNodeName;
nodeConfig(1).NodePosition = nodePostions(1,:); % node postions
nodeConfig(1).TxFormat = "VHT";% TxFormat matters Format for Transmission, WIFI 5:VHT WIFI 6:HE_SU
nodeConfig(1).BandAndChannel = {[5,16]}; % 5Ghz 16 channels
nodeConfig(1).Bandwidth = 80; % Channel Bandwidth = 80 mHz
nodeConfig(1).MPDUAggregation = true;
nodeConfig(1).NumTxChains = 1; % Number of transmit chains used during the transmission
nodeConfig(1).TxNumSTS = 1; 
% (similar to spatial streams) Number of space-time streams (STS) VHT & HE_SU valid in [1,8] 
%STS space-time streams must be less than/equal to the number of antennas
nodeConfig(1).TxMCS = 7; % Modulation and coding scheme (MCS) index for transmitting the frame. 
nodeConfig(1).DisableRTS = false; nodeConfig(1).DisableAck = false;

% WIFI 5 STA node configuration
nodeConfig(2).NodeName = staNodeName;
nodeConfig(2).NodePosition = nodePostions(2,:);
nodeConfig(2).TxFormat = "VHT";
nodeConfig(2).BandAndChannel = {[5,16]}; 
nodeConfig(2).Bandwidth = 80;
nodeConfig(2).MPDUAggregation = true;
nodeConfig(2).NumTxChains = 1;
nodeConfig(2).TxNumSTS = 1;
nodeConfig(2).TxMCS = 7;
nodeConfig(2).DisableRTS = false; nodeConfig(2).DisableAck = false;

%% Configure Transmission between AP and STA 
load('wlanTrafficConfig.mat');

trafficConfig = repmat(wlanTrafficConfig, 1, numNodes);

% Configure downlink application traffic 
% If we need to configure uplink, just change the name of sourcenode and
% destinationnode
trafficConfig(1).SourceNode = apNodeName;
trafficConfig(1).DestinationNode = staNodeName;
trafficConfig(1).DataRateKbps = 1e5; % 100Mbps % Rate, in Kbps, at which the application packets are generated
trafficConfig(1).PacketSize = 1500; % Size of the generated application packets (in bytes)
trafficConfig(1).AccessCategory = 0; 
% Access category (AC) Nonnegative integer in the range [0,3]
% 0 for best-effort traffic (BE)
% 1 for background traffic (BK)
% 2 for video traffic (VI)
% 3 for voice traffic (VO)

% uplink
trafficConfig(2).SourceNode = staNodeName;
trafficConfig(2).DestinationNode = apNodeName;
trafficConfig(2).DataRateKbps = 1e5; % 100Mbps % Rate, in Kbps, at which the application packets are generated
trafficConfig(2).PacketSize = 1500; % Size of the generated application packets (in bytes)
trafficConfig(2).AccessCategory = 0; 

%% Create WLAN Scenario

% Abstraction on MAC and PHY layers
wlanNodes = hCreateWLANNodes(nodeConfig,trafficConfig,"MACFrameAbstraction", true, "PHYAbstractionType",'TGax Evaluation Methodology Appendix 1');

%% Simulation

% Initialize the visualization parameters
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
hPlotStateTransition(statistics);

