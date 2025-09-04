classdef StateChangedEventData < event.EventData
    % 状态改变事件数据类
    
    properties
        OldState    % 旧状态
        NewState    % 新状态
    end
    
    methods
        function obj = StateChangedEventData(oldState, newState)
            obj.OldState = oldState;
            obj.NewState = newState;
        end
    end
end