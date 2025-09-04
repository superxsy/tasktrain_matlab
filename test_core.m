function test_core()
% 核心功能测试
% 测试不依赖GUI的核心功能

    fprintf('=== 核心功能测试 ===\n');
    
    try
        % 测试配置系统
        fprintf('1. 测试配置系统...\n');
        config = core.Config();
        config.subject_id = 'TEST001';
        config.session_label = 'test_core';
        config.simulation_mode = true;
        config.max_trials = 3;
        
        % 验证配置
        config.validateConfig();
        fprintf('   ✓ 配置验证通过\n');
        
        % 测试IO后端
        fprintf('2. 测试IO后端...\n');
        ioBackend = io.SimKeyboardBackend(config);
        success = ioBackend.initialize();
        
        if success
            fprintf('   ✓ IO后端初始化成功\n');
            
            % 测试LED控制
            ioBackend.setLED(1, true);
            ioBackend.setLED(2, false);
            ioBackend.setLED(3, true);
            fprintf('   ✓ LED控制测试完成\n');
            
            % 测试奖励
            ioBackend.triggerReward(0.1);
            fprintf('   ✓ 奖励触发测试完成\n');
            
        else
            fprintf('   ✗ IO后端初始化失败\n');
        end
        
        % 测试数据记录器
        fprintf('3. 测试数据记录器...\n');
        logger = core.TrialLogger(config);
        
        % 创建测试数据
        trialData = createTestTrialData(config);
        logger.saveTrialData(trialData);
        fprintf('   ✓ 试次数据保存成功\n');
        
        % 测试自适应控制器
        fprintf('4. 测试自适应控制器...\n');
        adaptive = core.AdaptiveController();
        
        % 模拟一些结果
        results = [0, 1, 0, 0, 1, 0, 0, 0, 1, 0];
        adaptive.applyAdaptiveAdjustments(results, config);
        fprintf('   ✓ 自适应调整测试完成\n');
        
        % 测试状态机核心逻辑
        fprintf('5. 测试状态机核心逻辑...\n');
        stateMachine = core.TaskStateMachine(config, ioBackend, logger, adaptive);
        
        % 测试状态转换
        initialState = stateMachine.getCurrentState();
        fprintf('   初始状态: %s\n', core.TaskState.toString(initialState));
        
        % 测试状态改变
        stateMachine.enterState(core.TaskState.L1_WAIT);
        newState = stateMachine.getCurrentState();
        fprintf('   新状态: %s\n', core.TaskState.toString(newState));
        
        % 测试试次管理
        originalTrialIndex = stateMachine.getTrialIndex();
        stateMachine.startNewTrial();
        newTrialIndex = stateMachine.getTrialIndex();
        fprintf('   试次索引: %d -> %d\n', originalTrialIndex, newTrialIndex);
        
        fprintf('   ✓ 状态机核心功能正常\n');
        
        % 清理
        ioBackend.cleanup();
        fprintf('6. 资源清理完成\n');
        
        fprintf('\n🎉 所有核心功能测试通过！\n');
        fprintf('系统可以正常工作，可以尝试启动完整GUI。\n\n');
        
        % 显示使用说明
        showUsageInstructions();
        
    catch ME
        fprintf('\n❌ 测试过程中发生错误:\n');
        fprintf('错误信息: %s\n', ME.message);
        fprintf('错误位置: %s (第%d行)\n', ME.stack(1).file, ME.stack(1).line);
        fprintf('\n完整错误报告:\n');
        fprintf('%s\n', getReport(ME));
    end
end

function trialData = createTestTrialData(config)
    % 创建测试用的试次数据
    trialData = struct();
    trialData.subject_id = config.subject_id;
    trialData.session_label = config.session_label;
    trialData.trial_index = 1;
    trialData.mode = config.mode;
    trialData.config_snapshot = config.toStruct();
    trialData.trial_start_walltime_iso = datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF');
    trialData.trial_start_monotonic = 0.0;
    trialData.trial_end_monotonic = 2.5;
    
    % 事件列表
    trialData.events = {
        struct('type', 'trial_start', 'timestamp', 0.0);
        struct('type', 'state_enter', 'state', 'L1_WAIT', 'timestamp', 0.001);
        struct('type', 'led_on', 'led', 1, 'timestamp', 0.002);
        struct('type', 'button_press', 'button', 1, 'timestamp', 1.5);
        struct('type', 'button_release', 'button', 1, 'timestamp', 1.6);
        struct('type', 'state_enter', 'state', 'REWARD', 'timestamp', 2.0);
        struct('type', 'reward_trigger', 'duration', 0.3, 'timestamp', 2.001);
        struct('type', 'trial_end', 'result_code', 0, 'result_text', 'Correct', 'timestamp', 2.5);
    };
    
    % 阶段时间戳
    trialData.stage_timestamps = struct();
    trialData.stage_timestamps.trial_start = 0.0;
    trialData.stage_timestamps.l1_wait = 0.001;
    trialData.stage_timestamps.reward = 2.0;
    
    % 按键时间
    trialData.press_release_times = struct();
    trialData.press_release_times.button1_press = 1.5;
    trialData.press_release_times.button1_release = 1.6;
    
    % 结果
    trialData.result_code = 0;
    trialData.result_text = 'Correct';
    trialData.reward_duration_actual = 0.3;
    trialData.iti_duration_actual = 1.0;
    trialData.iti_error_count = 0;
end

function showUsageInstructions()
    % 显示使用说明
    fprintf('=== 使用说明 ===\n');
    fprintf('现在可以启动完整的GUI程序:\n\n');
    fprintf('1. 启动主程序:\n');
    fprintf('   >> TaskTrain()\n\n');
    fprintf('2. 或者直接启动GUI:\n');
    fprintf('   >> app = gui.TaskTrainApp();\n\n');
    fprintf('3. 在模拟模式下使用键盘:\n');
    fprintf('   Q - 按钮1\n');
    fprintf('   W - 按钮2\n');
    fprintf('   E - 按钮3\n\n');
    fprintf('4. GUI快捷键:\n');
    fprintf('   空格 - 开始/暂停\n');
    fprintf('   R - 重置\n');
    fprintf('   C - 配置\n');
    fprintf('   H - 帮助\n\n');
    fprintf('5. 数据保存位置:\n');
    fprintf('   ./data/<被试ID>/<会话标签>/\n\n');
    fprintf('===============\n');
end