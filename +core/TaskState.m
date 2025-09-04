classdef TaskState < uint8
    % 任务状态枚举定义
    % 定义所有可能的实验状态
    
    enumeration
        ITI (1)           % 试次间隔状态
        L1_WAIT (2)       % 等待按压L1按钮
        I1 (3)            % L1和L2之间的间隔
        L2_WAIT (4)       % 等待按压L2按钮
        I2 (5)            % L2和L3之间的间隔
        L3_WAIT (6)       % 等待按压L3按钮
        REWARD (7)        % 奖励给予状态
        SHAPING_WAIT (8)  % 塑形模式等待状态
        PAUSED (9)        % 暂停状态
        FINISHED (10)     % 实验结束状态
    end
    
    methods (Static)
        function str = toString(state)
            % 将状态转换为字符串
            switch state
                case core.TaskState.ITI
                    str = 'ITI';
                case core.TaskState.L1_WAIT
                    str = 'L1_WAIT';
                case core.TaskState.I1
                    str = 'I1';
                case core.TaskState.L2_WAIT
                    str = 'L2_WAIT';
                case core.TaskState.I2
                    str = 'I2';
                case core.TaskState.L3_WAIT
                    str = 'L3_WAIT';
                case core.TaskState.REWARD
                    str = 'REWARD';
                case core.TaskState.SHAPING_WAIT
                    str = 'SHAPING_WAIT';
                case core.TaskState.PAUSED
                    str = 'PAUSED';
                case core.TaskState.FINISHED
                    str = 'FINISHED';
                otherwise
                    str = 'UNKNOWN';
            end
        end
    end
end