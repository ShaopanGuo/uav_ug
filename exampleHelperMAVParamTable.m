classdef exampleHelperMAVParamTable < handle
    %exampleHelperMAVParamTable stores parameters used in an UAV
    %   Parameters are stored according to MAVLink parameter definitions
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        %Maps PARAM_TYPE enum to MATLAB types
        ParamType = ["uint8", "int8", "uint16", "int16", "uint32", "int32", "uint64", "int64", "single", "double"];
    end
    
    properties
        %Parameters a map between param_index and a struct of {param_value,
        %param_id and param_index}
        Parameters
        %Count number of parameters
        Count
    end
    
    methods
        function obj = exampleHelperMAVParamTable()
            %Construct an empty parameter table
            obj.Parameters = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
        
        function insert(obj, msgExt)
            %insert Add new parameter to the table expressed as PARAM_VALUE
            %message
            obj.Count = msgExt.Payload.param_count;
            
            paramType = obj.ParamType(msgExt.Payload.param_type);
            paramValue = typecast(msgExt.Payload.param_value, paramType);
            obj.Parameters(double(msgExt.Payload.param_index)) = ...
                struct('ParamID', msgExt.Payload.param_id, ...
                'ParamValue', paramValue(1), ...
                'ParamIndex', msgExt.Payload.param_index);
        end
        
        function tbl = getTable(obj)
            %getTable returns all parameters in table format
            paramID = strings(size(obj.Parameters));
            paramType = strings(size(obj.Parameters));
            paramValue = zeros(size(obj.Parameters));
            paramIndex = zeros(size(obj.Parameters));
            
            values = obj.Parameters.values;
            for idx = 1:size(obj.Parameters,1)
                value = values{idx};
                paramID(idx) = value.ParamID;
                paramValue(idx) = value.ParamValue;
                paramIndex(idx) = value.ParamIndex;
                paramType(idx) = class(value.ParamValue);
            end
            
            tbl = table(paramIndex, paramID, paramValue, paramType, 'VariableNames', {'ParamIndex', 'ParamID', 'ParamValue', 'ParamType'});
        end
    end
end

