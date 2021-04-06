% Tune UAV Parameters Using MAVLink Parameter Protocol
%
% This example shows how to use a MAVLink parameter protocol in MATLAB and communicate with
% external ground control stations. A sample parameter protocol is provided for sending parameter
% updates from a simulated unmanned aerial vehicle (UAV) to a ground control station using MAVLink
% communication protocols. You setup the communication between the two MAVLink components, the
% UAV and the ground control station. Then, you send and receive parameter updates to tune
% parameter values for the UAV. Finally, if you use QGroundControl© as a ground control station, you
% can get these parameter updates from QGroundControl and see them reflected in the program
% window.

% Setup common dialect
dialect = mavlinkdialect("common.xml");    % This dialect is used to create
                                           % mavlinkio objects which can 
                                           % understand messages within the 
                                           % dialect. 
                                           
%% Setup UAV Connection
uavNode = mavlinkio(dialect,'SystemID',1,'ComponentID',1, ...
 'AutopilotType',"MAV_AUTOPILOT_GENERIC",'ComponentType',"MAV_TYPE_QUADROTOR");
    % represent a simulated UAV.
                                           
uavPort = 14750;
connect(uavNode,"UDP",'LocalPort',uavPort);    % The simulated UAV is 
                                               % listening on a UDP port 
                                               % for incoming messages. 
                                               % Connect to this UDP port 
                                               % using the uavNode object.
                                               
%% Setup GCS Connection

% Create a simulated ground control station (GCS) that listens on a different UDP port.
gcsNode = mavlinkio(dialect);
gcsPort = 14560;
connect(gcsNode,"UDP", 'LocalPort', gcsPort);

%% Setup Client and Subscriber

% Setup a client interface for the simulated UAV to communicate with the 
% ground control station.
clientStruct = uavNode.LocalClient;
uavClient = mavlinkclient(gcsNode,clientStruct.SystemID,clientStruct.ComponentID);
    % creates a MAVLink client interface for a MAVLink component. MAVLINK 
    % is a mavlinkio object. SYSID and COMPID are used to identify the 
    % MAVLink component. 
    
% Create a mavlinksub object to receive messages and process those messages 
% using a callback.
paramValueSub = mavlinksub(gcsNode,uavClient,'PARAM_VALUE','BufferSize',10,...
 'NewMessageFcn', @(~,msg)disp(msg.Payload));
%     The mavlinksub object subscribes to topics from the connected
%     MAVLink clients using a mavlinkio object. Use this mavlinksub
%     object to obtain the most recently received messages and call
%     functions to process newly received messages.
      
%       SUB = mavlinksub(MAVLINK, CLIENT, TOPIC) subscribes to a topic
%       from a client. MAVLINK is a mavlinkio object. CLIENT is a
%       mavlinkclient object, TOPIC is a string or non-negative integer
%       that identifies a MAVLink message.

%         obj = mavlinksub(__, NAME, VALUE) sets additional parameters using
%         name-value pairs:
%  
%             BufferSize:     - Buffer Size used by subscriber, default is 1
%             NewMessageFcn:  - Callback function for new message arrival. When
%                               it is [], no function would be called. default
%                               is []

%% Parameter Operations
% paramProtocol = exampleHelperMAVParamProtocol(uavNode);






