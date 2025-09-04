classdef ParameterAdjustedEventData < event.EventData
    % 参数调整事件数据类
    
    properties
        Performance    % 性能数据
        Config        % 调整后的配置
    end
    
    methods
        function obj = ParameterAdjustedEventData(performance, config)
            obj.Performance = performance;
            obj.Config = config;
        end
    end
end