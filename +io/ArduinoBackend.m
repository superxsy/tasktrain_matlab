classdef ArduinoBackend < io.IOBackend
    % Arduino硬件后端实现
    % 通过串口与Arduino Due通信
    
    properties (Access = private)
        arduino              % Arduino对象
        ledPins = [22, 23, 24]    % LED引脚定义
        buttonPins = [30, 31, 32] % 按钮引脚定义
        valvePin = 26        % 电磁阀引脚
        
        % 按钮状态管理
        lastButtonStates = [false, false, false]
        stableButtonStates = [false, false, false]
        debounceTimers = [0, 0, 0]
        debounceTime = 0.01  % 消抖时间（10ms）
        
        % LED状态缓存
        ledStates = [false, false, false]
        
        % 奖励控制
        rewardTimer = 0
        rewardDuration = 0
        rewardActive = false
        
        % 连接状态
        isConnected = false
        connectionTime = 0
        
        % 配置参数
        config
    end
    
    methods
        function obj = ArduinoBackend(config)
            % 构造函数
            obj.config = config;
            if nargin > 0 && ~isempty(config)
                obj.ledPins = config.led_pins;
                obj.buttonPins = config.button_pins;
                obj.valvePin = config.valve_pin;
                obj.debounceTime = config.debounce_time;
            end
        end
        
        function success = initialize(obj)
            % 初始化Arduino连接
            success = false;
            
            try
                % 查找Arduino端口
                port = obj.findArduinoPort();
                if isempty(port)
                    warning('未找到Arduino设备');
                    return;
                end
                
                fprintf('连接Arduino: %s\n', port);
                
                % 创建Arduino对象
                obj.arduino = arduino(port, 'Due');
                
                % 等待连接稳定
                pause(2);
                
                % 配置引脚
                obj.configurePins();
                
                % 执行自检
                if obj.performSelfTest()
                    obj.isConnected = true;
                    obj.connectionTime = tic;
                    success = true;
                    fprintf('Arduino初始化成功\n');
                else
                    warning('Arduino自检失败');
                    obj.cleanup();
                end
                
            catch ME
                warning('Arduino初始化失败: %s', ME.message);
                obj.cleanup();
            end
        end
        
        function port = findArduinoPort(obj)
            % 自动查找Arduino端口
            port = '';
            
            % 如果配置中指定了端口，直接使用
            if ~isempty(obj.config.arduino_port)
                port = obj.config.arduino_port;
                return;
            end
            
            try
                % 获取可用串口列表
                serialPorts = serialportlist;
                
                % 在Windows上查找Arduino
                if ispc
                    % 查找包含"Arduino"或"USB"的端口
                    for i = 1:length(serialPorts)
                        portName = char(serialPorts(i));
                        if contains(lower(portName), {'com', 'usb'})
                            try
                                % 尝试连接
                                testArduino = arduino(portName, 'Due');
                                delete(testArduino);
                                port = portName;
                                break;
                            catch
                                % 继续尝试下一个端口
                                continue;
                            end
                        end
                    end
                else
                    % 在Linux/Mac上查找
                    for i = 1:length(serialPorts)
                        portName = char(serialPorts(i));
                        if contains(lower(portName), {'usb', 'acm', 'tty'})
                            try
                                testArduino = arduino(portName, 'Due');
                                delete(testArduino);
                                port = portName;
                                break;
                            catch
                                continue;
                            end
                        end
                    end
                end
                
            catch ME
                warning('端口搜索失败: %s', ME.message);
            end
        end
        
        function configurePins(obj)
            % 配置Arduino引脚
            try
                % 配置LED引脚为输出
                for i = 1:length(obj.ledPins)
                    configurePin(obj.arduino, obj.ledPins(i), 'DigitalOutput');
                    writeDigitalPin(obj.arduino, obj.ledPins(i), 0);
                end
                
                % 配置按钮引脚为输入（带上拉电阻）
                for i = 1:length(obj.buttonPins)
                    configurePin(obj.arduino, obj.buttonPins(i), 'DigitalInput');
                end
                
                % 配置电磁阀引脚为输出
                configurePin(obj.arduino, obj.valvePin, 'DigitalOutput');
                writeDigitalPin(obj.arduino, obj.valvePin, 0);
                
                fprintf('引脚配置完成\n');
                
            catch ME
                error('引脚配置失败: %s', ME.message);
            end
        end
        
        function success = performSelfTest(obj)
            % 执行硬件自检
            success = false;
            
            try
                fprintf('执行硬件自检...\n');
                
                % 测试LED
                fprintf('  测试LED...\n');
                for i = 1:3
                    obj.setLED(i, true);
                    pause(0.2);
                    obj.setLED(i, false);
                    pause(0.1);
                end
                
                % 测试按钮
                fprintf('  测试按钮读取...\n');
                for i = 1:3
                    state = obj.readButton(i);
                    fprintf('    按钮%d: %s\n', i, num2str(state));
                end
                
                % 测试电磁阀
                fprintf('  测试电磁阀...\n');
                writeDigitalPin(obj.arduino, obj.valvePin, 1);
                pause(0.1);
                writeDigitalPin(obj.arduino, obj.valvePin, 0);
                
                success = true;
                fprintf('硬件自检完成\n');
                
            catch ME
                warning('硬件自检失败: %s', ME.message);
            end
        end
        
        function setLED(obj, ledIndex, state)
            % 设置LED状态
            if ledIndex < 1 || ledIndex > 3
                warning('无效的LED索引: %d', ledIndex);
                return;
            end
            
            try
                if obj.isConnected
                    writeDigitalPin(obj.arduino, obj.ledPins(ledIndex), state);
                end
                obj.ledStates(ledIndex) = state;
            catch ME
                warning('LED控制失败: %s', ME.message);
                obj.checkConnection();
            end
        end
        
        function buttonState = readButton(obj, buttonIndex)
            % 读取按钮状态（带消抖）
            buttonState = false;
            
            if buttonIndex < 1 || buttonIndex > 3
                warning('无效的按钮索引: %d', buttonIndex);
                return;
            end
            
            try
                if obj.isConnected
                    % 读取原始状态（低电平有效）
                    rawState = ~readDigitalPin(obj.arduino, obj.buttonPins(buttonIndex));
                    
                    % 应用消抖算法
                    buttonState = obj.debounceButton(buttonIndex, rawState);
                else
                    buttonState = false;
                end
            catch ME
                warning('按钮读取失败: %s', ME.message);
                obj.checkConnection();
                buttonState = false;
            end
        end
        
        function debouncedState = debounceButton(obj, buttonIndex, currentState)
            % 按钮消抖算法
            persistent lastUpdateTime;
            if isempty(lastUpdateTime)
                lastUpdateTime = zeros(1, 3);
            end
            
            currentTime = toc(obj.connectionTime);
            
            if currentState ~= obj.lastButtonStates(buttonIndex)
                obj.debounceTimers(buttonIndex) = currentTime;
                obj.lastButtonStates(buttonIndex) = currentState;
            end
            
            if (currentTime - obj.debounceTimers(buttonIndex)) > obj.debounceTime
                obj.stableButtonStates(buttonIndex) = currentState;
            end
            
            debouncedState = obj.stableButtonStates(buttonIndex);
        end
        
        function triggerReward(obj, duration)
            % 触发奖励
            try
                if obj.isConnected
                    writeDigitalPin(obj.arduino, obj.valvePin, 1);
                end
                
                obj.rewardActive = true;
                obj.rewardDuration = duration;
                obj.rewardTimer = tic;
                
            catch ME
                warning('奖励触发失败: %s', ME.message);
                obj.checkConnection();
            end
        end
        
        function eventList = processEvents(obj)
            % 处理输入事件
            eventList = {};
            
            if ~obj.isConnected
                return;
            end
            
            % 处理奖励计时
            if obj.rewardActive && toc(obj.rewardTimer) >= obj.rewardDuration
                try
                    writeDigitalPin(obj.arduino, obj.valvePin, 0);
                catch ME
                    warning('奖励关闭失败: %s', ME.message);
                end
                obj.rewardActive = false;
            end
            
            % 检查按钮状态变化
            for i = 1:3
                currentState = obj.readButton(i);
                
                if currentState ~= obj.stableButtonStates(i)
                    % 按钮状态改变
                    if currentState
                        % 按钮按下
                        eventList{end+1} = struct('type', 'button_press', 'button', i, 'timestamp', toc(obj.connectionTime));
                    else
                        % 按钮松开
                        eventList{end+1} = struct('type', 'button_release', 'button', i, 'timestamp', toc(obj.connectionTime));
                    end
                end
            end
        end
        
        function checkConnection(obj)
            % 检查连接状态
            try
                if obj.isConnected && ~isempty(obj.arduino)
                    % 尝试读取一个引脚来测试连接
                    readDigitalPin(obj.arduino, obj.buttonPins(1));
                else
                    obj.isConnected = false;
                end
            catch
                obj.isConnected = false;
                warning('Arduino连接丢失');
            end
        end
        
        function cleanup(obj)
            % 清理资源
            try
                % 关闭所有LED和电磁阀
                if obj.isConnected && ~isempty(obj.arduino)
                    for i = 1:3
                        writeDigitalPin(obj.arduino, obj.ledPins(i), 0);
                    end
                    writeDigitalPin(obj.arduino, obj.valvePin, 0);
                end
                
                % 清理Arduino对象
                if ~isempty(obj.arduino)
                    delete(obj.arduino);
                    obj.arduino = [];
                end
                
                obj.isConnected = false;
                fprintf('Arduino资源清理完成\n');
                
            catch ME
                warning('资源清理失败: %s', ME.message);
            end
        end
        
        % Getter方法
        function connected = isHardwareConnected(obj)
            connected = obj.isConnected;
        end
        
        function states = getLEDStates(obj)
            states = obj.ledStates;
        end
        
        function states = getButtonStates(obj)
            states = obj.stableButtonStates;
        end
        
        function active = isRewardActive(obj)
            active = obj.rewardActive;
        end
    end
end