classdef (Abstract) IOBackend < handle
    % IO后端抽象基类
    % 定义硬件接口的标准方法
    
    methods (Abstract)
        % 设置LED状态
        % ledIndex: LED索引 (1-3)
        % state: true=亮, false=灭
        setLED(obj, ledIndex, state)
        
        % 读取按钮状态
        % buttonIndex: 按钮索引 (1-3)
        % 返回: true=按下, false=松开
        buttonState = readButton(obj, buttonIndex)
        
        % 触发奖励
        % duration: 奖励持续时间（秒）
        triggerReward(obj, duration)
        
        % 处理输入事件
        % 返回: 事件结构体数组
        eventList = processEvents(obj)
        
        % 初始化硬件
        % 返回: true=成功, false=失败
        success = initialize(obj)
        
        % 清理资源
        cleanup(obj)
    end
    
    methods
        function obj = IOBackend()
            % 基类构造函数
        end
    end
end