classdef exampleHelperMAVParamProtocol < handle
    % exampleHelperMAVParamProtocol MAVLink Parameter Protocol Implementation
    %   exampleHelperMAVParamProtocol Handle class that stores methods and properties of
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        % UAVInfo stores drone information
        UAVInfo
        
        % UAVParameters stores drone parameters
        UAVParameters
        
        % ParamRequestListSubscriber subscriber to PARAM_REQUEST_LIST messgaes
        ParamRequestListSubscriber
        
        % ParamRequestReadSubscriber subsriber to PARAM_REQUEST _READ messages
        ParamRequestReadSubscriber
        
        % ParamSetSubscriber subscriber to PARAM_SET messages
        ParamSetSubscriber
    end
    properties (Constant)
        %MLTypeToParamType Maps MATLAB types to MAV_PARAM_TYPE enum
        MLTypeToParamType = struct(...
            "uint8", 1, "int8", 2, "uint16", 3, "int16", 4, "uin32", 5, "int32", 6, ...
            "uint64", 7, "int64", 8, "single", 9, "double", 10);
    end
    methods
        function obj = exampleHelperMAVParamProtocol(io)
            %exampleHelperMAVParamProtocol Contruct an instance of this class
            
            % Log drone information
            obj.UAVInfo = io.LocalClient;
            
            % Function to populate UAVParameters property with parameter table
            createTable(obj, io);
            
            % Create subscriber to PARAM_REQUEST_LIST with a callback
            % function to send a list of parameters as messages
            obj.ParamRequestListSubscriber = mavlinksub(io, 'PARAM_REQUEST_LIST', ...
                'BufferSize', 30, 'NewMessageFcn', ...
                @(~,msgExt)exampleHelperMAVParamProtocol.paramRequestListCallback(msgExt, io, obj));
            
            % Create subscriber to PARAM_REQUEST_READ with a callback
            % function to send the parameter value
            obj.ParamRequestReadSubscriber = mavlinksub(io, 'PARAM_REQUEST_READ', ...
                'BufferSize', 30, 'NewMessageFcn', ...
                @(~,msgExt)exampleHelperMAVParamProtocol.paramRequestReadCallback(msgExt,io, obj));
            
            % Create subscriber to PARAM_SET with a callback function to
            % set a parameter value
            obj.ParamSetSubscriber = mavlinksub(io, 'PARAM_SET', ...
                'BufferSize', 30, 'NewMessageFcn', ...
                @(~,msgExt)exampleHelperMAVParamProtocol.paramSetCallback(msgExt, io, obj));
            
        end
        
        function tbl = getparams(obj)
            %getparams returns all parameters in table format
            tbl = obj.UAVParameters.getTable();
        end
        
        function delete(obj)
            %delete all subscribers
            delete(obj.ParamRequestListSubscriber);
            delete(obj.ParamRequestReadSubscriber);
            delete(obj.ParamSetSubscriber);
        end
        
    end
    
    methods (Access=private)
        
        function createTable(obj, io)
            %createTable populates UAVParameters property with parameter table
            % number of parameters param_count
            n = 3;
            % assign UAVParameters property to a Parameter Table type
            obj.UAVParameters = exampleHelperMAVParamTable;
            
            % Add new parameter to the table expressed as PARAM_VALUE
            % message
            insert(obj.UAVParameters, exampleHelperMAVParamProtocol.createParam(io, 'MAX_ROLL_RATE',9,0,90,n));
            insert(obj.UAVParameters, exampleHelperMAVParamProtocol.createParam(io, 'MAX_PITCH_RATE',9,1,90,n));
            insert(obj.UAVParameters, exampleHelperMAVParamProtocol.createParam(io, 'MAX_YAW_RATE',9,2,90,n));
        end
    end
    
    methods (Static)
        function paramRequestListCallback(msg, io, protocol)
            %paramRequestListCallback gets called for every incoming PARAM_REQUEST_LIST message
            
            if (msg.Payload.target_system == protocol.UAVInfo.SystemID) && ...
                    (msg.Payload.target_component == 0 || msg.Payload.target_component == protocol.UAVInfo.ComponentID)
                
                % Number of entries in the parameter table
                N = height(getTable(protocol.UAVParameters));
                % collect all parameters in table format
                table = getTable(protocol.UAVParameters);
                % setup a dialect to send messgaes
                dialect = io.Dialect;
                client = mavlinkclient(io, msg.SystemID, msg.ComponentID);
                
                for i = 1:N
                    msgsend = dialect.createmsg('PARAM_VALUE');
                    msgsend.Payload.param_count(:) = protocol.UAVParameters.Count;
                    msgsend.Payload.param_index(:) = table.ParamIndex(i);
                    msgsend.Payload.param_id(:) = table.ParamID(i);
                    paramValue = cast(table.ParamValue(i), table.ParamType(i));
                    msgsend.Payload.param_type(:) = protocol.MLTypeToParamType.(table.ParamType(i));
                    if (msgsend.Payload.param_type < 3)
                        msgsend.Payload.param_value(:) = typecast([paramValue, 0, 0, 0], 'single');
                    elseif (msgsend.Payload.param_type < 5)
                        msgsend.Payload.param_value(:) = typecast([paramValue, 0,], 'single');
                    else
                        msgsend.Payload.param_value(:) = typecast(paramValue, 'single');
                    end
                    % send PARAM_VALUE message in loop for each parameter
                    io.sendmsg(msgsend, client)
                    
                end
                
            end
        end
        
        function paramRequestReadCallback(msg, io, protocol)
            %paramRequestReadCallback gets called for every incoming PARAM_REQUEST_READ message
            
            if (msg.Payload.target_system == protocol.UAVInfo.SystemID) && ...
                    (msg.Payload.target_component == 0 || msg.Payload.target_component == protocol.UAVInfo.ComponentID)
                
                % collect all parameter in table format
                table = getTable(protocol.UAVParameters);
                
                % setup a dialect to send messsages
                dialect = io.Dialect;
                client = mavlinkclient(io, msg.SystemID, msg.ComponentID);
                
                % get the table index from the incoming message
                i = msg.Payload.param_index;
                
                % create PARAM_VALUE message
                msgsend = dialect.createmsg('PARAM_VALUE');
                msgsend.Payload.param_count(:) = protocol.UAVParameters.Count;
                msgsend.Payload.param_index(:) = i;
                msgsend.Payload.param_id(:) = table.ParamID(i+1);
                paramValue = cast(table.ParamValue(i+1), table.ParamType(i+1));
                msgsend.Payload.param_type(:) = protocol.MLTypeToParamType.(table.ParamType(i+1));
                if (msgsend.Payload.param_type < 3)
                    msgsend.Payload.param_value(:) = typecast([paramValue, 0, 0, 0], 'single');
                elseif (msgsend.Payload.param_type < 5)
                    msgsend.Payload.param_value(:) = typecast([paramValue, 0,], 'single');
                else
                    msgsend.Payload.param_value(:) = typecast(paramValue, 'single');
                end
                
                % send PARAM_VALUE message for the specified parameter
                io.sendmsg(msgsend, client)
                
            end
            
        end
        
        function paramSetCallback(msg, io, protocol)
            %paramSetCallback gets called for every PARAM_SET message
            
            if (msg.Payload.target_system == protocol.UAVInfo.SystemID) && ...
                    (msg.Payload.target_component == 0 || msg.Payload.target_component == protocol.UAVInfo.ComponentID)
                
                % collect all parameter in table format
                table = getTable(protocol.UAVParameters);
                
                % get the table index to be set from the message payload
                % information
                for i = 1:size(table,1)
                    if strcmp(string(msg.Payload.param_id), table.ParamID(i))
                        index = i-1;
                    end
                end
                
                % create a temporary struct to store messgae payload data
                stemp.ParamID = msg.Payload.param_id;
                stemp.ParamValue = msg.Payload.param_value;
                stemp.ParamIndex = index;
                
                % update parameters with the new value
                protocol.UAVParameters.Parameters(index)=stemp;
                
                table = getTable(protocol.UAVParameters);
                % create a dialect to send messgaes
                dialect = io.Dialect;
                client = mavlinkclient(io, msg.SystemID, msg.ComponentID);
                i = index;
                
                % create PARAM_VALUE message
                msgsend = dialect.createmsg('PARAM_VALUE');
                msgsend.Payload.param_count(:) = protocol.UAVParameters.Count;
                msgsend.Payload.param_index(:) = i;
                msgsend.Payload.param_id(:) = table.ParamID(i+1);
                paramValue = cast(table.ParamValue(i+1), table.ParamType(i+1));
                msgsend.Payload.param_type(:) = protocol.MLTypeToParamType.(table.ParamType(i+1));
                if (msgsend.Payload.param_type < 3)
                    msgsend.Payload.param_value(:) = typecast([paramValue, 0, 0, 0], 'single');
                elseif (msgsend.Payload.param_type < 5)
                    msgsend.Payload.param_value(:) = typecast([paramValue, 0,], 'single');
                else
                    msgsend.Payload.param_value(:) = typecast(paramValue, 'single');
                end
                
                % send PARAM_VALUE message for the modified parameter
                io.sendmsg(msgsend, client)
                
            end
            
        end
        
        function msg = createParam(io, id, type, index, value, count)
            %createParam create a new PARAM_VALUE message
            msg = io.Dialect.createmsg('PARAM_VALUE');
            
            % Modify message payload to create a parameter entry
            msg.Payload.param_count(:) = count;
            msg.Payload.param_id(1:strlength(id)) = id;
            msg.Payload.param_type(:) = type;
            msg.Payload.param_index(:) = index;
            msg.Payload.param_value(:) = value;
        end
    end
end

