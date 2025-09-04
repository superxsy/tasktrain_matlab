classdef TrialCompletedEventData < event.EventData
    % 试次完成事件数据类
    
    properties
        TrialData    % 试次数据
    end
    
    methods
        function obj = TrialCompletedEventData(trialData)
            obj.TrialData = trialData;
        end
    end
end