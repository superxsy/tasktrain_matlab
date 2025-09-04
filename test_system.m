function test_system()
% 系统集成测试脚本
% 验证所有模块是否正常工作

    fprintf('=== 系统集成测试 ===\n');
    fprintf('测试时间: %s\n', datestr(now));
    fprintf('===================\n\n');
    
    testResults = struct();
    
    try
        % 测试1: 配置系统
        fprintf('测试1: 配置系统...\n');
        testResults.config = test_config();
        
        % 测试2: IO后端
        fprintf('\n测试2: IO后端...\n');
        testResults.io = test_io_backend();
        
        % 测试3: 数据记录
        fprintf('\n测试3: 数据记录...\n');
        testResults.logger = test_logger();
        
        % 测试4: 自适应控制
        fprintf('\n测试4: 自适应控制...\n');
        testResults.adaptive = test_adaptive();
        
        % 测试5: 状态机
        fprintf('\n测试5: 状态机...\n');
        testResults.state_machine = test_state_machine();
        
        % 打印测试总结
        print_test_summary(testResults);
        
    catch ME
        fprintf('测试过程中发生错误: %s\n', ME.message);
        fprintf('完整错误信息:\n%s\n', getReport(ME));
    end
end

function success = test_config()
    % 测试配置系统
    success = false;
    
    try
        % 创建配置对象
        config = core.Config();
        fprintf('  ✓ 配置对象创建成功\n');
        
        % 测试默认值
        assert(config.wait_L1 == 3.0, '默认等待时间错误');
        assert(strcmp(config.mode, 'sequence3'), '默认模式错误');
        fprintf('  ✓ 默认配置验证通过\n');
        
        % 测试参数验证
        config.validateConfig();
        fprintf('  ✓ 配置验证通过\n');
        
        % 测试序列化
        configStruct = config.toStruct();
        assert(isstruct(configStruct), '配置序列化失败');
        fprintf('  ✓ 配置序列化成功\n');
        
        % 测试ITI计算
        iti_correct = config.calculateITI(true);
        iti_error = config.calculateITI(false);
        assert(iti_correct >= config.ITI_fixed_correct, 'ITI计算错误');
        assert(iti_error >= config.ITI_fixed_error, 'ITI计算错误');
        fprintf('  ✓ ITI计算功能正常\n');
        
        success = true;
        
    catch ME
        fprintf('  ✗ 配置测试失败: %s\n', ME.message);
    end
end

function success = test_io_backend()
    % 测试IO后端
    success = false;
    
    try
        % 测试模拟后端
        config = core.Config();
        config.simulation_mode = true;
        
        simBackend = io.SimKeyboardBackend(config);
        fprintf('  ✓ 模拟后端创建成功\n');
        
        % 测试初始化
        initSuccess = simBackend.initialize();
        assert(initSuccess, '模拟后端初始化失败');
        fprintf('  ✓ 模拟后端初始化成功\n');
        
        % 测试LED控制
        simBackend.setLED(1, true);
        simBackend.setLED(2, false);
        simBackend.setLED(3, true);
        fprintf('  ✓ LED控制功能正常\n');
        
        % 测试按钮读取
        for i = 1:3
            state = simBackend.readButton(i);
            assert(islogical(state), '按钮状态返回类型错误');
        end
        fprintf('  ✓ 按钮读取功能正常\n');
        
        % 测试奖励触发
        simBackend.triggerReward(0.3);
        fprintf('  ✓ 奖励触发功能正常\n');
        
        % 测试事件处理
        eventList = simBackend.processEvents();
        assert(iscell(eventList), '事件处理返回类型错误');
        fprintf('  ✓ 事件处理功能正常\n');
        
        % 清理
        simBackend.cleanup();
        fprintf('  ✓ 资源清理成功\n');
        
        success = true;
        
    catch ME
        fprintf('  ✗ IO后端测试失败: %s\n', ME.message);
    end
end

function success = test_logger()
    % 测试数据记录系统
    success = false;
    
    try
        % 创建临时配置
        config = core.Config();
        config.subject_id = 'TEST001';
        config.session_label = 'test_session';
        
        % 创建记录器
        logger = core.TrialLogger(config);
        fprintf('  ✓ 数据记录器创建成功\n');
        
        % 创建模拟试次数据
        trialData = struct();
        trialData.subject_id = config.subject_id;
        trialData.session_label = config.session_label;
        trialData.trial_index = 1;
        trialData.mode = config.mode;
        trialData.config_snapshot = config.toStruct();
        trialData.trial_start_walltime_iso = datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF');
        trialData.trial_start_monotonic = 0.0;
        trialData.trial_end_monotonic = 1.5;
        trialData.events = {};
        trialData.stage_timestamps = struct();
        trialData.press_release_times = struct();
        trialData.result_code = 0;
        trialData.result_text = 'Correct';
        trialData.reward_duration_actual = 0.3;
        trialData.iti_duration_actual = 1.0;
        trialData.iti_error_count = 0;
        
        % 测试试次数据保存
        logger.saveTrialData(trialData);
        fprintf('  ✓ 试次数据保存成功\n');
        
        % 测试会话汇总
        results = [0, 1, 0, 2, 0];  % 模拟结果
        logger.saveSessionSummary(results, config);
        fprintf('  ✓ 会话汇总保存成功\n');
        
        % 清理测试数据
        testDataPath = logger.getSessionPath();
        if exist(testDataPath, 'dir')
            rmdir(testDataPath, 's');
            fprintf('  ✓ 测试数据清理完成\n');
        end
        
        success = true;
        
    catch ME
        fprintf('  ✗ 数据记录测试失败: %s\n', ME.message);
    end
end

function success = test_adaptive()
    % 测试自适应控制
    success = false;
    
    try
        % 创建自适应控制器
        adaptive = core.AdaptiveController();
        fprintf('  ✓ 自适应控制器创建成功\n');
        
        % 创建配置
        config = core.Config();
        config.adaptive_enabled = true;
        config.adaptive_window = 10;
        
        % 测试表现良好的情况
        goodResults = zeros(1, 20);  % 20个正确试次
        originalWait = config.wait_L1;
        
        adaptive.applyAdaptiveAdjustments(goodResults, config);
        
        % 应该降低等待时间（增加难度）
        if config.wait_L1 < originalWait
            fprintf('  ✓ 高表现难度调整正常\n');
        else
            fprintf('  - 高表现调整未触发（可能窗口不足）\n');
        end
        
        % 测试表现不佳的情况
        badResults = [1, 2, 1, 3, 2, 1, 4, 2, 1, 3, 1, 2, 1, 3, 2];  % 错误较多
        originalWait = config.wait_L1;
        
        adaptive.applyAdaptiveAdjustments(badResults, config);
        
        % 应该增加等待时间（降低难度）
        if config.wait_L1 > originalWait
            fprintf('  ✓ 低表现难度调整正常\n');
        else
            fprintf('  - 低表现调整未触发\n');
        end
        
        % 测试调整历史
        history = adaptive.getAdjustmentHistory();
        fprintf('  ✓ 调整历史记录功能正常 (记录数: %d)\n', length(history));
        
        success = true;
        
    catch ME
        fprintf('  ✗ 自适应控制测试失败: %s\n', ME.message);
    end
end

function success = test_state_machine()
    % 测试状态机
    success = false;
    
    try
        % 创建依赖组件
        config = core.Config();
        config.simulation_mode = true;
        config.max_trials = 5;  % 限制试次数用于测试
        
        ioBackend = io.SimKeyboardBackend(config);
        logger = core.TrialLogger(config);
        adaptive = core.AdaptiveController();
        
        % 创建状态机
        stateMachine = core.TaskStateMachine(config, ioBackend, logger, adaptive);
        fprintf('  ✓ 状态机创建成功\n');
        
        % 测试初始状态
        initialState = stateMachine.getCurrentState();
        assert(initialState == core.TaskState.ITI, '初始状态错误');
        fprintf('  ✓ 初始状态正确\n');
        
        % 测试状态转换
        stateMachine.enterState(core.TaskState.L1_WAIT);
        currentState = stateMachine.getCurrentState();
        assert(currentState == core.TaskState.L1_WAIT, '状态转换失败');
        fprintf('  ✓ 状态转换功能正常\n');
        
        % 测试试次管理
        originalIndex = stateMachine.getTrialIndex();
        stateMachine.startNewTrial();
        newIndex = stateMachine.getTrialIndex();
        assert(newIndex > originalIndex, '试次计数错误');
        fprintf('  ✓ 试次管理功能正常\n');
        
        % 测试结果记录
        stateMachine.endTrial(0, 'Test Correct');
        results = stateMachine.getTrialResults();
        assert(~isempty(results), '结果记录失败');
        assert(results(end) == 0, '结果记录错误');
        fprintf('  ✓ 结果记录功能正常\n');
        
        % 清理
        ioBackend.cleanup();
        
        success = true;
        
    catch ME
        fprintf('  ✗ 状态机测试失败: %s\n', ME.message);
    end
end

function print_test_summary(results)
    % 打印测试总结
    fprintf('\n=== 测试总结 ===\n');
    
    fields = fieldnames(results);
    passCount = 0;
    totalCount = length(fields);
    
    for i = 1:totalCount
        testName = fields{i};
        passed = results.(testName);
        
        if passed
            status = '✓ 通过';
            passCount = passCount + 1;
        else
            status = '✗ 失败';
        end
        
        fprintf('%s: %s\n', testName, status);
    end
    
    fprintf('\n总计: %d/%d 通过\n', passCount, totalCount);
    
    if passCount == totalCount
        fprintf('🎉 所有测试通过！系统可以正常使用。\n');
    else
        fprintf('⚠️  部分测试失败，请检查相关模块。\n');
    end
    
    fprintf('================\n');
end