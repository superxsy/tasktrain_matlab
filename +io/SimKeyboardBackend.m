classdef SimKeyboardBackend < io.IOBackend
    % 键盘模拟后端实现
    % 用于在没有Arduino硬件时进行测试
    
    properties (Access = private)
        % 状态模拟
        ledStates = [false, false, false]
        buttonStates = [false, false, false]
        lastButtonStates = [false, false, false]
        
        % 键盘映射
        keyMap = containers.Map({'q', 'w', 'e'}, {1, 2, 3})
        
        % 奖励模拟
        rewardActive = false
        rewardTimer = 0
        rewardDuration = 0
        
        % 时间基准
        startTime = 0
        
        % 图形界面句柄（用于显示LED状态）
        figHandle = []
        ledIndicators = []
    end
    
    methods
        function obj = SimKeyboardBackend(config)
            % 构造函数
            if nargin > 0
                % 可以根据配置调整键盘映射
            end
        end
        
        function success = initialize(obj)
            % 初始化模拟后端
            success = true;
            obj.startTime = tic;
            
            % 创建LED状态显示窗口
            obj.createStatusWindow();
            
            fprintf('键盘模拟后端初始化成功\n');
            fprintf('按键映射: Q=按钮1, W=按钮2, E=按钮3\n');
        end
        
        function createStatusWindow(obj)
            % 创建状态显示窗口
            try
                obj.figHandle = figure('Name', 'Arduino模拟器', ...
                                      'NumberTitle', 'off', ...
                                      'Position', [100, 100, 400, 200], ...
                                      'MenuBar', 'none', ...
                                      'ToolBar', 'none', ...
                                      'Resize', 'off', ...
                                      'CloseRequestFcn', @(~,~) obj.cleanup());
                
                % 创建LED指示器
                for i = 1:3
                    obj.ledIndicators(i) = rectangle('Position', [50 + (i-1)*100, 100, 50, 50], ...
                                                    'Curvature', [1, 1], ...
                                                    'FaceColor', [0.3, 0.3, 0.3], ...
                                                    'EdgeColor', 'black', ...
                                                    'LineWidth', 2);
                    
                    text(75 + (i-1)*100, 70, sprintf('LED%d', i), ...
                         'HorizontalAlignment', 'center', ...
                         'FontSize', 12, 'FontWeight', 'bold');
                end
                
                % 添加按键说明
                text(200, 40, '按键: Q=按钮1, W=按钮2, E=按钮3', ...
                     'HorizontalAlignment', 'center', ...
                     'FontSize', 10);
                
                text(200, 20, '奖励状态: 未激活', ...
                     'HorizontalAlignment', 'center', ...
                     'FontSize', 10, ...
                     'Tag', 'RewardStatus');
                
                axis equal;
                axis([0, 400, 0, 200]);
                axis off;
                
                % 设置键盘回调
                set(obj.figHandle, 'KeyPressFcn', @obj.onKeyPress);
                set(obj.figHandle, 'KeyReleaseFcn', @obj.onKeyRelease);
                
            catch ME
                warning('状态窗口创建失败: %s', ME.message);
            end
        end
        
        function onKeyPress(obj, ~, eventData)
            % 键盘按下回调
            key = lower(eventData.Key);
            if obj.keyMap.isKey(key)
                buttonIndex = obj.keyMap(key);
                obj.buttonStates(buttonIndex) = true;
            end
        end
        
        function onKeyRelease(obj, ~, eventData)
            % 键盘松开回调
            key = lower(eventData.Key);
            if obj.keyMap.isKey(key)
                buttonIndex = obj.keyMap(key);
                obj.buttonStates(buttonIndex) = false;
            end
        end
        
        function setLED(obj, ledIndex, state)
            % 设置LED状态
            if ledIndex < 1 || ledIndex > 3
                warning('无效的LED索引: %d', ledIndex);
                return;
            end
            
            obj.ledStates(ledIndex) = state;
            
            % 更新图形显示
            if ~isempty(obj.figHandle) && isvalid(obj.figHandle)
                try
                    if state
                        set(obj.ledIndicators(ledIndex), 'FaceColor', [0, 1, 0]); % 绿色
                    else
                        set(obj.ledIndicators(ledIndex), 'FaceColor', [0.3, 0.3, 0.3]); % 灰色
                    end
                    drawnow;
                catch
                    % 图形更新失败，忽略
                end
            end
        end
        
        function buttonState = readButton(obj, buttonIndex)
            % 读取按钮状态
            if buttonIndex < 1 || buttonIndex > 3
                warning('无效的按钮索引: %d', buttonIndex);
                buttonState = false;
                return;
            end
            
            buttonState = obj.buttonStates(buttonIndex);
        end
        
        function triggerReward(obj, duration)
            % 触发奖励
            obj.rewardActive = true;
            obj.rewardDuration = duration;
            obj.rewardTimer = tic;
            
            % 更新奖励状态显示
            if ~isempty(obj.figHandle) && isvalid(obj.figHandle)
                try
                    rewardText = findobj(obj.figHandle, 'Tag', 'RewardStatus');
                    if ~isempty(rewardText)
                        set(rewardText, 'String', sprintf('奖励状态: 激活 (%.1fs)', duration), ...
                                       'Color', [0, 0.8, 0]);
                    end
                    drawnow;
                catch
                    % 图形更新失败，忽略
                end
            end
            
            fprintf('模拟奖励触发: %.1f秒\n', duration);
        end
        
        function eventList = processEvents(obj)
            % 处理输入事件
            eventList = {};
            
            % 处理奖励计时
            if obj.rewardActive && toc(obj.rewardTimer) >= obj.rewardDuration
                obj.rewardActive = false;
                
                % 更新奖励状态显示
                if ~isempty(obj.figHandle) && isvalid(obj.figHandle)
                    try
                        rewardText = findobj(obj.figHandle, 'Tag', 'RewardStatus');
                        if ~isempty(rewardText)
                            set(rewardText, 'String', '奖励状态: 未激活', ...
                                           'Color', [0, 0, 0]);
                        end
                        drawnow;
                    catch
                        % 图形更新失败，忽略
                    end
                end
            end
            
            % 检查按钮状态变化
            for i = 1:3
                currentState = obj.buttonStates(i);
                
                if currentState ~= obj.lastButtonStates(i)
                    % 按钮状态改变
                    if currentState
                        % 按钮按下
                        eventList{end+1} = struct('type', 'button_press', ...
                                              'button', i, ...
                                              'timestamp', toc(obj.startTime));
                        fprintf('模拟按钮 %d 按下\n', i);
                    else
                        % 按钮松开
                        eventList{end+1} = struct('type', 'button_release', ...
                                              'button', i, ...
                                              'timestamp', toc(obj.startTime));
                        fprintf('模拟按钮 %d 松开\n', i);
                    end
                    
                    obj.lastButtonStates(i) = currentState;
                end
            end
        end
        
        function cleanup(obj)
            % 清理资源
            % 关闭所有LED
            for i = 1:3
                obj.setLED(i, false);
            end
            
            obj.rewardActive = false;
            
            % 关闭状态窗口
            if ~isempty(obj.figHandle) && isvalid(obj.figHandle)
                delete(obj.figHandle);
            end
            
            fprintf('键盘模拟后端清理完成\n');
        end
        
        % Getter方法
        function connected = isHardwareConnected(obj)
            % 模拟模式始终连接
            connected = true;
        end
        
        function states = getLEDStates(obj)
            states = obj.ledStates;
        end
        
        function states = getButtonStates(obj)
            states = obj.buttonStates;
        end
        
        function active = isRewardActive(obj)
            active = obj.rewardActive;
        end
        
        function showHelp(obj)
            % 显示帮助信息
            helpText = {
                '键盘模拟模式使用说明:',
                '',
                '按键映射:',
                '  Q - 按钮1 (L1)',
                '  W - 按钮2 (L2)', 
                '  E - 按钮3 (L3)',
                '',
                'LED状态:',
                '  绿色圆圈 - LED开启',
                '  灰色圆圈 - LED关闭',
                '',
                '奖励状态显示在窗口底部'
            };
            
            msgbox(helpText, '模拟器帮助', 'help');
        end
    end
end