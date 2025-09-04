classdef TaskStateMachine < handle
    % 任务状态机核心类
    % 管理实验的状态转换和逻辑控制
    
    properties (Access = private)
        config              % 配置对象
        ioBackend          % IO后端接口
        logger             % 数据记录器
        adaptive           % 自适应控制器
        
        % 状态相关
        currentState       % 当前状态
        stateStartTime     % 状态开始时间
        sessionStartTime   % 会话开始时间
        trialStartTime     % 试次开始时间
        
        % 试次数据
        trialIndex = 0     % 当前试次索引
        trialResults = []  % 试次结果历史
        trialEvents = {}   % 当前试次事件列表
        
        % 按键状态
        buttonStates = [false, false, false]  % 三个按钮状态
        lastButtonStates = [false, false, false]
        currentPressTime = 0  % 当前按键开始时间
        currentPressButton = 0  % 当前按压的按钮
        
        % ITI错误计数
        itiErrorCount = 0
        
        % 控制标志
        isPaused = false
        isRunning = false
        forceStop = false
        
        % 时间戳缓存
        stageTimestamps = struct()
        pressReleaseTimes = struct()
        
    end
    
    properties (Access = public)
        % Random mode support - public for testing and debugging
        currentTrialSequence = [1, 2, 3]  % Current trial's sequence order
        currentTrialShapingLed = 1        % Current trial's shaping LED
        sequenceStepIndex = 1             % Current step in sequence (1, 2, or 3)
    end
    
    events
        StateChanged       % 状态改变事件
        TrialCompleted     % 试次完成事件
        SessionCompleted   % 会话完成事件
        ErrorOccurred      % 错误发生事件
    end
    
    methods
        function obj = TaskStateMachine(config, ioBackend, logger, adaptive)
            % 构造函数
            obj.config = config;
            obj.ioBackend = ioBackend;
            obj.logger = logger;
            obj.adaptive = adaptive;
            
            obj.currentState = core.TaskState.ITI;
            obj.sessionStartTime = tic;  % 初始化时间基准
            
            % Initialize trial parameters based on config
            obj.setupTrialParameters();
            
            obj.resetSession();
        end
        
        function startSession(obj)
            % 开始新会话
            obj.config.generateSessionLabel();
            obj.resetSession();
            obj.isRunning = true;
            obj.isPaused = false;
            obj.sessionStartTime = tic;
            
            % 初始化硬件
            if ~obj.ioBackend.initialize()
                error('硬件初始化失败');
            end
            
            % 设置所有LED为关闭状态
            for i = 1:3
                obj.ioBackend.setLED(i, false);
            end
            
            % 开始第一个试次
            obj.startNewTrial();
            
            fprintf('会话开始: %s - %s\n', obj.config.subject_id, obj.config.session_label);
        end
        
        function pauseSession(obj)
            % 暂停会话
            obj.isPaused = true;
            obj.enterState(core.TaskState.PAUSED);
        end
        
        function resumeSession(obj)
            % 恢复会话
            obj.isPaused = false;
            obj.enterState(core.TaskState.ITI);
        end
        
        function stopSession(obj)
            % 停止会话
            obj.forceStop = true;
            obj.isRunning = false;
            obj.enterState(core.TaskState.FINISHED);
            
            % 关闭所有硬件
            for i = 1:3
                obj.ioBackend.setLED(i, false);
            end
            
            % 保存最终数据
            if obj.trialIndex > 0
                obj.logger.saveSessionSummary(obj.trialResults, obj.config);
            end
            
            obj.ioBackend.cleanup();
            notify(obj, 'SessionCompleted');
            
            fprintf('会话结束，共完成 %d 个试次\n', obj.trialIndex);
        end
        
        function update(obj, currentTime)
            % 主更新循环
            if ~obj.isRunning || obj.isPaused
                return;
            end
            
            % 处理硬件事件
            eventList = obj.ioBackend.processEvents();
            for i = 1:length(eventList)
                obj.processEvent(eventList{i});
            end
            
            % 状态机更新
            obj.updateStateMachine(currentTime);
            
            % 检查会话是否应该结束
            if obj.trialIndex >= obj.config.max_trials && ~obj.forceStop
                obj.stopSession();
            end
        end
        
        function updateStateMachine(obj, currentTime)
            % 状态机逻辑更新
            stateElapsedTime = toc(obj.stateStartTime);
            
            switch obj.currentState
                case core.TaskState.ITI
                    obj.updateITI(stateElapsedTime);
                    
                case core.TaskState.L1_WAIT
                    obj.updateWaitState(stateElapsedTime, 1, obj.config.wait_L1, core.TaskState.I1);
                    
                case core.TaskState.I1
                    obj.updateInterval(stateElapsedTime, obj.config.I1, core.TaskState.L2_WAIT);
                    
                case core.TaskState.L2_WAIT
                    obj.updateWaitState(stateElapsedTime, 2, obj.config.wait_L2, core.TaskState.I2);
                    
                case core.TaskState.I2
                    obj.updateInterval(stateElapsedTime, obj.config.I2, core.TaskState.L3_WAIT);
                    
                case core.TaskState.L3_WAIT
                    obj.updateWaitState(stateElapsedTime, 3, obj.config.wait_L3, core.TaskState.REWARD);
                    
                case core.TaskState.SHAPING_WAIT
                    obj.updateShapingWait(stateElapsedTime);
                    
                case core.TaskState.REWARD
                    obj.updateReward(stateElapsedTime);
            end
        end
        
        function updateITI(obj, elapsedTime)
            % 更新ITI状态
            % ITI期间的按键被记录为ITI错误，但不影响试次结果
            currentTime = toc(obj.sessionStartTime);
            expectedDuration = obj.stageTimestamps.iti_duration;
            
            if elapsedTime >= expectedDuration
                % ITI结束，检查所有按钮是否都已松开
                if ~any(obj.buttonStates)
                    % 开始下一阶段
                    if strcmp(obj.config.mode, 'sequence3')
                        obj.enterState(core.TaskState.L1_WAIT);
                    else  % shaping1
                        obj.enterState(core.TaskState.SHAPING_WAIT);
                    end
                else
                    % 等待按钮松开
                    obj.logEvent('wait_release', currentTime);
                end
            end
        end
        
        function updateWaitState(obj, elapsedTime, ledIndex, waitTime, nextState)
            % 更新等待状态（L1_WAIT, L2_WAIT, L3_WAIT）
            currentTime = toc(obj.sessionStartTime);
            
            % 检查是否超时
            if elapsedTime >= waitTime
                if obj.currentPressButton == 0
                    % 未按压，记录错误
                    obj.endTrial(1, 'No Press');
                    return;
                end
            end
            
            % 检查松开窗口
            obj.checkReleaseWindow(currentTime);
        end
        
        function updateInterval(obj, elapsedTime, intervalTime, nextState)
            % 更新间隔状态（I1, I2）
            if elapsedTime >= intervalTime
                obj.enterState(nextState);
            end
        end
        
        function updateShapingWait(obj, elapsedTime)
            % 更新塑形等待状态
            waitTime = obj.config.(['wait_L' num2str(obj.config.shaping_led)]);
            
            if elapsedTime >= waitTime
                if obj.currentPressButton == 0
                    obj.endTrial(1, 'No Press');
                    return;
                end
            end
            
            obj.checkReleaseWindow(toc(obj.sessionStartTime));
        end
        
        function updateReward(obj, elapsedTime)
            % 更新奖励状态
            if elapsedTime >= obj.config.R_duration
                obj.endTrial(0, 'Correct');
            end
        end
        
        function checkReleaseWindow(obj, currentTime)
            % 检查松开窗口逻辑
            if obj.currentPressButton > 0
                pressDuration = currentTime - obj.currentPressTime;
                
                % 规则1：按压时间超过release_window立即失败
                if pressDuration > obj.config.release_window
                    obj.endTrial(3, 'Hold Too Long');
                    return;
                end
            end
        end
        
        function processEvent(obj, event)
            % 处理输入事件
            currentTime = toc(obj.sessionStartTime);
            
            switch event.type
                case 'button_press'
                    obj.processButtonPress(event.button, currentTime);
                    
                case 'button_release'
                    obj.processButtonRelease(event.button, currentTime);
            end
        end
        
        function processButtonPress(obj, button, currentTime)
            % 处理按钮按下事件
            obj.buttonStates(button) = true;
            obj.logEvent('button_press', currentTime, struct('button', button));
            
            % ITI期间的按键
            if obj.currentState == core.TaskState.ITI
                obj.itiErrorCount = obj.itiErrorCount + 1;
                obj.logEvent('iti_error', currentTime, struct('button', button));
                return;
            end
            
            % 间隔期间的按键（过早按压）
            if obj.currentState == core.TaskState.I1 || obj.currentState == core.TaskState.I2
                obj.endTrial(4, 'Premature Press');
                return;
            end
            
            % 等待状态下的按键
            if obj.currentState == core.TaskState.L1_WAIT || ...
               obj.currentState == core.TaskState.L2_WAIT || ...
               obj.currentState == core.TaskState.L3_WAIT || ...
               obj.currentState == core.TaskState.SHAPING_WAIT
                
                expectedButton = obj.getExpectedButton();
                
                if button == expectedButton
                    % 正确按键
                    obj.currentPressButton = button;
                    obj.currentPressTime = currentTime;
                    obj.pressReleaseTimes.(['button' num2str(button) '_press']) = currentTime;
                else
                    % 错误按键
                    obj.endTrial(2, 'Wrong Button');
                    return;
                end
            end
        end
        
        function processButtonRelease(obj, button, currentTime)
            % 处理按钮松开事件
            obj.buttonStates(button) = false;
            obj.logEvent('button_release', currentTime, struct('button', button));
            
            % 只处理当前按压按钮的松开
            if button == obj.currentPressButton
                obj.pressReleaseTimes.(['button' num2str(button) '_release']) = currentTime;
                
                % 检查是否可以进入下一状态
                if obj.currentState == core.TaskState.L1_WAIT
                    obj.enterState(core.TaskState.I1);
                elseif obj.currentState == core.TaskState.L2_WAIT
                    obj.enterState(core.TaskState.I2);
                elseif obj.currentState == core.TaskState.L3_WAIT || ...
                       obj.currentState == core.TaskState.SHAPING_WAIT
                    obj.enterState(core.TaskState.REWARD);
                end
                
                obj.currentPressButton = 0;
                obj.currentPressTime = 0;
            end
        end
        
        function expectedButton = getExpectedButton(obj)
            % 获取当前状态下期望的按钮
            switch obj.currentState
                case core.TaskState.L1_WAIT
                    expectedButton = obj.currentTrialSequence(1);
                case core.TaskState.L2_WAIT
                    expectedButton = obj.currentTrialSequence(2);
                case core.TaskState.L3_WAIT
                    expectedButton = obj.currentTrialSequence(3);
                case core.TaskState.SHAPING_WAIT
                    expectedButton = obj.currentTrialShapingLed;
                otherwise
                    expectedButton = 0;
            end
        end
        
        function setupTrialParameters(obj)
            % Setup parameters for current trial based on random mode settings
            
            % Setup sequence for sequence3 mode
            if strcmp(obj.config.mode, 'sequence3')
                if obj.config.sequence_random_mode
                    % Generate random sequence
                    obj.currentTrialSequence = randperm(3);
                else
                    % Use custom sequence or default
                    if ~isempty(obj.config.custom_sequence)
                        obj.currentTrialSequence = obj.config.custom_sequence;
                    else
                        obj.currentTrialSequence = [1, 2, 3];
                    end
                end
            end
            
            % Setup LED for shaping1 mode
            if strcmp(obj.config.mode, 'shaping1')
                if obj.config.shaping_random_mode
                    % Choose random LED
                    obj.currentTrialShapingLed = randi(3);
                else
                    % Use configured LED
                    obj.currentTrialShapingLed = obj.config.shaping_led;
                end
            end
            
            % Log trial parameters (only if session has started)
            if obj.isRunning
                currentTime = toc(obj.sessionStartTime);
                if strcmp(obj.config.mode, 'sequence3')
                    obj.logEvent('trial_sequence', currentTime, ...
                        struct('sequence', obj.currentTrialSequence));
                else
                    obj.logEvent('trial_shaping_led', currentTime, ...
                        struct('led', obj.currentTrialShapingLed));
                end
            end
        end
        
        function enterState(obj, newState)
            % 进入新状态
            oldState = obj.currentState;
            obj.currentState = newState;
            obj.stateStartTime = tic;
            currentTime = obj.getSafeCurrentTime();
            
            % 记录状态转换
            obj.logEvent('state_enter', currentTime, struct('state', core.TaskState.toString(newState)));
            obj.stageTimestamps.(lower(core.TaskState.toString(newState))) = currentTime;
            
            % 状态特定的初始化
            switch newState
                case core.TaskState.ITI
                    % 关闭所有LED
                    for i = 1:3
                        obj.ioBackend.setLED(i, false);
                    end
                    
                case {core.TaskState.L1_WAIT, core.TaskState.L2_WAIT, core.TaskState.L3_WAIT}
                    % 关闭所有LED，然后打开对应的LED
                    for i = 1:3
                        obj.ioBackend.setLED(i, false);
                    end
                    ledIndex = obj.getExpectedButton();
                    obj.ioBackend.setLED(ledIndex, true);
                    obj.logEvent('led_on', currentTime, struct('led', ledIndex));
                    
                case core.TaskState.SHAPING_WAIT
                    % 关闭所有LED，然后打开塑形LED
                    for i = 1:3
                        obj.ioBackend.setLED(i, false);
                    end
                    obj.ioBackend.setLED(obj.currentTrialShapingLed, true);
                    obj.logEvent('led_on', currentTime, struct('led', obj.currentTrialShapingLed));
                    
                case core.TaskState.REWARD
                    % 关闭所有LED，触发奖励
                    for i = 1:3
                        obj.ioBackend.setLED(i, false);
                    end
                    obj.ioBackend.triggerReward(obj.config.R_duration);
                    obj.logEvent('reward_trigger', currentTime, struct('duration', obj.config.R_duration));
            end
            
            % 通知状态改变
            notify(obj, 'StateChanged', core.StateChangedEventData(oldState, newState));
        end
        
        function startNewTrial(obj)
            % 开始新试次
            obj.trialIndex = obj.trialIndex + 1;
            obj.trialStartTime = tic;
            obj.trialEvents = {};
            obj.stageTimestamps = struct();
            obj.pressReleaseTimes = struct();
            obj.itiErrorCount = 0;
            obj.currentPressButton = 0;
            obj.currentPressTime = 0;
            obj.sequenceStepIndex = 1;
            
            % Setup trial-specific parameters
            obj.setupTrialParameters();
            
            % 记录试次开始
            currentTime = toc(obj.sessionStartTime);
            obj.logEvent('trial_start', currentTime);
            obj.stageTimestamps.trial_start = currentTime;
            
            % 计算ITI时间（第一个试次不需要ITI）
            if obj.trialIndex == 1
                obj.stageTimestamps.iti_duration = 0;
                if strcmp(obj.config.mode, 'sequence3')
                    obj.enterState(core.TaskState.L1_WAIT);
                else
                    obj.enterState(core.TaskState.SHAPING_WAIT);
                end
            else
                % 使用上一个试次的结果决定ITI时间
                lastResult = obj.trialResults(end);
                isCorrect = (lastResult == 0);
                itiDuration = obj.config.calculateITI(isCorrect);
                obj.stageTimestamps.iti_duration = itiDuration;
                obj.enterState(core.TaskState.ITI);
            end
            
            fprintf('开始试次 %d/%d\n', obj.trialIndex, obj.config.max_trials);
        end
        
        function endTrial(obj, resultCode, resultText)
            % 结束当前试次
            currentTime = toc(obj.sessionStartTime);
            
            % 记录试次结束
            obj.logEvent('trial_end', currentTime, struct('result_code', resultCode, 'result_text', resultText));
            
            % 保存试次结果
            obj.trialResults(end+1) = resultCode;
            
            % 创建试次数据
            trialData = obj.createTrialData(resultCode, resultText, currentTime);
            
            % 保存试次数据
            obj.logger.saveTrialData(trialData);
            
            % 应用自适应调整
            if obj.config.adaptive_enabled
                obj.adaptive.applyAdaptiveAdjustments(obj.trialResults, obj.config);
            end
            
            % 通知试次完成
            notify(obj, 'TrialCompleted', core.TrialCompletedEventData(trialData));
            
            % 开始下一个试次
            obj.startNewTrial();
        end
        
        function trialData = createTrialData(obj, resultCode, resultText, endTime)
            % 创建试次数据结构
            trialData = struct();
            trialData.subject_id = obj.config.subject_id;
            trialData.session_label = obj.config.session_label;
            trialData.trial_index = obj.trialIndex;
            trialData.mode = obj.config.mode;
            trialData.config_snapshot = obj.config.toStruct();
            
            % 时间戳
            trialData.trial_start_walltime_iso = datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF');
            trialData.trial_start_monotonic = obj.stageTimestamps.trial_start;
            trialData.trial_end_monotonic = endTime;
            
            % 事件列表
            trialData.events = obj.trialEvents;
            
            % 阶段时间戳
            trialData.stage_timestamps = obj.stageTimestamps;
            
            % 按键松开时间
            trialData.press_release_times = obj.pressReleaseTimes;
            
            % 结果
            trialData.result_code = resultCode;
            trialData.result_text = resultText;
            
            % 奖励和ITI时间
            if resultCode == 0
                trialData.reward_duration_actual = obj.config.R_duration;
            else
                trialData.reward_duration_actual = 0;
            end
            
            if ~isempty(fieldnames(obj.stageTimestamps)) && isfield(obj.stageTimestamps, 'iti_duration')
                trialData.iti_duration_actual = obj.stageTimestamps.iti_duration;
            else
                trialData.iti_duration_actual = 0;
            end
            
            % ITI错误计数
            trialData.iti_error_count = obj.itiErrorCount;
        end
        
        function logEvent(obj, eventType, timestamp, data)
            % 记录事件
            event = struct();
            event.type = eventType;
            event.timestamp = timestamp;
            
            if nargin > 3
                fields = fieldnames(data);
                for i = 1:length(fields)
                    event.(fields{i}) = data.(fields{i});
                end
            end
            
            obj.trialEvents{end+1} = event;
        end
        
        function resetSession(obj)
            % 重置会话
            obj.trialIndex = 0;
            obj.trialResults = [];
            obj.itiErrorCount = 0;
            obj.currentPressButton = 0;
            obj.currentPressTime = 0;
            obj.buttonStates = [false, false, false];
            obj.lastButtonStates = [false, false, false];
            obj.forceStop = false;
        end
        
        % Getter方法
        function state = getCurrentState(obj)
            state = obj.currentState;
        end
        
        function index = getTrialIndex(obj)
            index = obj.trialIndex;
        end
        
        function results = getTrialResults(obj)
            results = obj.trialResults;
        end
        
        function count = getITIErrorCount(obj)
            count = obj.itiErrorCount;
        end
        
        function running = isSessionRunning(obj)
            running = obj.isRunning;
        end
        
        function paused = isSessionPaused(obj)
            paused = obj.isPaused;
        end
        
        function currentTime = getSafeCurrentTime(obj)
            % 安全地获取当前时间
            if obj.sessionStartTime == 0
                currentTime = 0;
            else
                currentTime = toc(obj.sessionStartTime);
            end
        end
    end
end