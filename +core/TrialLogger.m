classdef TrialLogger < handle
    % 试次数据记录器
    % 负责保存和管理实验数据
    
    properties (Access = private)
        dataDirectory = 'data'  % 数据目录
        sessionPath = ''        % 当前会话路径
        trialCounter = 0        % 试次计数器
        sessionStartTime = ''   % 会话开始时间
        
        % 文件句柄缓存
        csvFileHandle = []
        csvFilePath = ''
        
        % 数据缓存
        sessionData = []
    end
    
    methods
        function obj = TrialLogger(config)
            % 构造函数
            if nargin > 0
                obj.initializeSession(config);
            end
        end
        
        function initializeSession(obj, config)
            % 初始化会话
            obj.sessionStartTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            
            % 创建会话目录
            subjectDir = fullfile(obj.dataDirectory, config.subject_id);
            sessionDir = fullfile(subjectDir, config.session_label);
            
            if ~exist(subjectDir, 'dir')
                mkdir(subjectDir);
            end
            
            if ~exist(sessionDir, 'dir')
                mkdir(sessionDir);
            end
            
            obj.sessionPath = sessionDir;
            obj.trialCounter = 0;
            
            % 初始化CSV文件
            obj.initializeCSVFile(config);
            
            % 保存配置文件
            obj.saveConfigSnapshot(config);
            
            fprintf('数据记录器初始化完成: %s\n', obj.sessionPath);
        end
        
        function initializeCSVFile(obj, config)
            % 初始化CSV汇总文件
            obj.csvFilePath = fullfile(obj.sessionPath, 'session_summary.csv');
            
            % 定义CSV头部
            headers = {
                'trial_index', 'subject_id', 'session_label', 'mode', ...
                'trial_start_walltime', 'trial_start_monotonic', 'trial_end_monotonic', ...
                'result_code', 'result_text', ...
                'stage_iti', 'stage_l1_wait', 'stage_i1', 'stage_l2_wait', ...
                'stage_i2', 'stage_l3_wait', 'stage_reward', 'stage_shaping_wait', ...
                'button1_press', 'button1_release', 'button2_press', 'button2_release', ...
                'button3_press', 'button3_release', ...
                'reward_duration_actual', 'iti_duration_actual', 'iti_error_count', ...
                'wait_L1', 'wait_L2', 'wait_L3', 'I1', 'I2', 'release_window', ...
                'ITI_fixed_correct', 'ITI_rand_correct', 'ITI_fixed_error', 'ITI_rand_error'
            };
            
            % 创建CSV文件并写入头部
            try
                obj.csvFileHandle = fopen(obj.csvFilePath, 'w');
                fprintf(obj.csvFileHandle, '%s\n', strjoin(headers, ','));
                fclose(obj.csvFileHandle);
                obj.csvFileHandle = [];
                
                fprintf('CSV文件创建成功: %s\n', obj.csvFilePath);
            catch ME
                error('CSV文件创建失败: %s', ME.message);
            end
        end
        
        function saveConfigSnapshot(obj, config)
            % 保存配置快照
            configPath = fullfile(obj.sessionPath, 'config_snapshot.json');
            
            try
                configStruct = config.toStruct();
                configStruct.session_start_time = obj.sessionStartTime;
                
                jsonStr = jsonencode(configStruct, 'PrettyPrint', true);
                fid = fopen(configPath, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                
                fprintf('配置快照保存成功: %s\n', configPath);
            catch ME
                warning('配置快照保存失败: %s', ME.message);
            end
        end
        
        function saveTrialData(obj, trialData)
            % 保存单个试次数据
            obj.trialCounter = obj.trialCounter + 1;
            
            % 保存JSON格式的详细数据
            obj.saveTrialJSON(trialData);
            
            % 追加到CSV汇总文件
            obj.appendToCSV(trialData);
            
            % 缓存数据用于会话汇总
            obj.sessionData = [obj.sessionData; trialData];
        end
        
        function saveTrialJSON(obj, trialData)
            % 保存JSON格式的试次数据
            filename = sprintf('trial_%04d.json', trialData.trial_index);
            filepath = fullfile(obj.sessionPath, filename);
            
            try
                jsonStr = jsonencode(trialData, 'PrettyPrint', true);
                fid = fopen(filepath, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
            catch ME
                warning('试次JSON保存失败: %s', ME.message);
            end
        end
        
        function appendToCSV(obj, trialData)
            % 追加数据到CSV文件
            try
                % 准备CSV行数据
                csvRow = obj.prepareCSVRow(trialData);
                
                % 追加到文件
                fid = fopen(obj.csvFilePath, 'a');
                fprintf(fid, '%s\n', csvRow);
                fclose(fid);
                
            catch ME
                warning('CSV追加失败: %s', ME.message);
            end
        end
        
        function csvRow = prepareCSVRow(obj, trialData)
            % 准备CSV行数据
            values = {};
            
            % 基础信息
            values{end+1} = num2str(trialData.trial_index);
            values{end+1} = sprintf('"%s"', trialData.subject_id);
            values{end+1} = sprintf('"%s"', trialData.session_label);
            values{end+1} = sprintf('"%s"', trialData.mode);
            
            % 时间戳
            values{end+1} = sprintf('"%s"', trialData.trial_start_walltime_iso);
            values{end+1} = num2str(trialData.trial_start_monotonic, '%.6f');
            values{end+1} = num2str(trialData.trial_end_monotonic, '%.6f');
            
            % 结果
            values{end+1} = num2str(trialData.result_code);
            values{end+1} = sprintf('"%s"', trialData.result_text);
            
            % 阶段时间戳
            stageFields = {'iti', 'l1_wait', 'i1', 'l2_wait', 'i2', 'l3_wait', 'reward', 'shaping_wait'};
            for i = 1:length(stageFields)
                if isfield(trialData.stage_timestamps, stageFields{i})
                    values{end+1} = num2str(trialData.stage_timestamps.(stageFields{i}), '%.6f');
                else
                    values{end+1} = '';
                end
            end
            
            % 按键时间
            buttonFields = {'button1_press', 'button1_release', 'button2_press', ...
                           'button2_release', 'button3_press', 'button3_release'};
            for i = 1:length(buttonFields)
                if isfield(trialData.press_release_times, buttonFields{i})
                    values{end+1} = num2str(trialData.press_release_times.(buttonFields{i}), '%.6f');
                else
                    values{end+1} = '';
                end
            end
            
            % 实际时长
            values{end+1} = num2str(trialData.reward_duration_actual, '%.3f');
            values{end+1} = num2str(trialData.iti_duration_actual, '%.3f');
            values{end+1} = num2str(trialData.iti_error_count);
            
            % 配置参数
            config = trialData.config_snapshot;
            configFields = {'wait_L1', 'wait_L2', 'wait_L3', 'I1', 'I2', 'release_window', ...
                           'ITI_fixed_correct', 'ITI_rand_correct', 'ITI_fixed_error', 'ITI_rand_error'};
            for i = 1:length(configFields)
                if isfield(config, configFields{i})
                    values{end+1} = num2str(config.(configFields{i}), '%.3f');
                else
                    values{end+1} = '';
                end
            end
            
            csvRow = strjoin(values, ',');
        end
        
        function saveSessionSummary(obj, trialResults, config)
            % 保存会话汇总统计
            summaryPath = fullfile(obj.sessionPath, 'session_analysis.json');
            
            try
                summary = obj.calculateSessionSummary(trialResults, config);
                
                jsonStr = jsonencode(summary, 'PrettyPrint', true);
                fid = fopen(summaryPath, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                
                fprintf('会话汇总保存成功: %s\n', summaryPath);
                obj.printSessionSummary(summary);
                
            catch ME
                warning('会话汇总保存失败: %s', ME.message);
            end
        end
        
        function summary = calculateSessionSummary(obj, trialResults, config)
            % 计算会话汇总统计
            summary = struct();
            
            % 基础信息
            summary.subject_id = config.subject_id;
            summary.session_label = config.session_label;
            summary.session_start_time = obj.sessionStartTime;
            summary.session_end_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            summary.total_trials = length(trialResults);
            
            % 结果统计
            if ~isempty(trialResults)
                summary.correct_trials = sum(trialResults == 0);
                summary.error_trials = sum(trialResults > 0);
                summary.accuracy = summary.correct_trials / summary.total_trials * 100;
                
                % 错误类型统计
                summary.no_press_errors = sum(trialResults == 1);
                summary.wrong_button_errors = sum(trialResults == 2);
                summary.hold_too_long_errors = sum(trialResults == 3);
                summary.premature_press_errors = sum(trialResults == 4);
                
                % 错误率
                summary.no_press_rate = summary.no_press_errors / summary.total_trials * 100;
                summary.wrong_button_rate = summary.wrong_button_errors / summary.total_trials * 100;
                summary.hold_too_long_rate = summary.hold_too_long_errors / summary.total_trials * 100;
                summary.premature_press_rate = summary.premature_press_errors / summary.total_trials * 100;
                
                % 连续正确试次
                summary.max_consecutive_correct = obj.calculateMaxConsecutive(trialResults, 0);
                summary.max_consecutive_errors = obj.calculateMaxConsecutive(trialResults > 0);
                
                % 学习曲线（每20个试次的正确率）
                if summary.total_trials >= 20
                    windowSize = 20;
                    numWindows = floor(summary.total_trials / windowSize);
                    learningCurve = zeros(1, numWindows);
                    
                    for i = 1:numWindows
                        startIdx = (i-1) * windowSize + 1;
                        endIdx = i * windowSize;
                        windowResults = trialResults(startIdx:endIdx);
                        learningCurve(i) = sum(windowResults == 0) / windowSize * 100;
                    end
                    
                    summary.learning_curve = learningCurve;
                    summary.initial_accuracy = learningCurve(1);
                    summary.final_accuracy = learningCurve(end);
                    summary.improvement = summary.final_accuracy - summary.initial_accuracy;
                end
            else
                summary.correct_trials = 0;
                summary.error_trials = 0;
                summary.accuracy = 0;
            end
            
            % 会话配置
            summary.config = config.toStruct();
            
            % 数据文件信息
            summary.data_directory = obj.sessionPath;
            summary.csv_file = obj.csvFilePath;
        end
        
        function maxConsecutive = calculateMaxConsecutive(obj, results, targetValue)
            % 计算最大连续目标值的数量
            maxConsecutive = 0;
            currentConsecutive = 0;
            
            if islogical(targetValue)
                compareResults = targetValue;
            else
                compareResults = (results == targetValue);
            end
            
            for i = 1:length(compareResults)
                if compareResults(i)
                    currentConsecutive = currentConsecutive + 1;
                    maxConsecutive = max(maxConsecutive, currentConsecutive);
                else
                    currentConsecutive = 0;
                end
            end
        end
        
        function printSessionSummary(obj, summary)
            % 打印会话汇总到控制台
            fprintf('\n=== 会话汇总 ===\n');
            fprintf('被试: %s\n', summary.subject_id);
            fprintf('会话: %s\n', summary.session_label);
            fprintf('开始时间: %s\n', summary.session_start_time);
            fprintf('结束时间: %s\n', summary.session_end_time);
            fprintf('总试次: %d\n', summary.total_trials);
            
            if summary.total_trials > 0
                fprintf('正确试次: %d (%.1f%%)\n', summary.correct_trials, summary.accuracy);
                fprintf('错误试次: %d\n', summary.error_trials);
                fprintf('\n错误类型分布:\n');
                fprintf('  未按压: %d (%.1f%%)\n', summary.no_press_errors, summary.no_press_rate);
                fprintf('  按错按钮: %d (%.1f%%)\n', summary.wrong_button_errors, summary.wrong_button_rate);
                fprintf('  按住过久: %d (%.1f%%)\n', summary.hold_too_long_errors, summary.hold_too_long_rate);
                fprintf('  过早按压: %d (%.1f%%)\n', summary.premature_press_errors, summary.premature_press_rate);
                
                fprintf('\n连续性分析:\n');
                fprintf('  最大连续正确: %d\n', summary.max_consecutive_correct);
                fprintf('  最大连续错误: %d\n', summary.max_consecutive_errors);
                
                if isfield(summary, 'learning_curve')
                    fprintf('\n学习曲线:\n');
                    fprintf('  初始正确率: %.1f%%\n', summary.initial_accuracy);
                    fprintf('  最终正确率: %.1f%%\n', summary.final_accuracy);
                    fprintf('  改善程度: %.1f%%\n', summary.improvement);
                end
            end
            
            fprintf('\n数据文件保存在: %s\n', summary.data_directory);
            fprintf('==================\n\n');
        end
        
        function data = loadSessionData(obj, sessionPath)
            % 加载会话数据
            if nargin < 2
                sessionPath = obj.sessionPath;
            end
            
            csvPath = fullfile(sessionPath, 'session_summary.csv');
            
            if exist(csvPath, 'file')
                try
                    data = readtable(csvPath);
                    fprintf('会话数据加载成功: %s\n', csvPath);
                catch ME
                    warning('会话数据加载失败: %s', ME.message);
                    data = [];
                end
            else
                warning('找不到会话数据文件: %s', csvPath);
                data = [];
            end
        end
        
        function exportData(obj, format, outputPath)
            % 导出数据到指定格式
            if nargin < 3
                outputPath = obj.sessionPath;
            end
            
            switch lower(format)
                case 'mat'
                    obj.exportToMAT(outputPath);
                case 'excel'
                    obj.exportToExcel(outputPath);
                case 'csv'
                    % CSV已经自动生成
                    fprintf('CSV文件已存在: %s\n', obj.csvFilePath);
                otherwise
                    warning('不支持的导出格式: %s', format);
            end
        end
        
        function exportToMAT(obj, outputPath)
            % 导出到MAT文件
            matPath = fullfile(outputPath, 'session_data.mat');
            
            try
                % 加载CSV数据
                sessionTable = obj.loadSessionData();
                
                if ~isempty(sessionTable)
                    save(matPath, 'sessionTable', '-v7.3');
                    fprintf('MAT文件导出成功: %s\n', matPath);
                end
            catch ME
                warning('MAT文件导出失败: %s', ME.message);
            end
        end
        
        function exportToExcel(obj, outputPath)
            % 导出到Excel文件
            excelPath = fullfile(outputPath, 'session_data.xlsx');
            
            try
                % 加载CSV数据
                sessionTable = obj.loadSessionData();
                
                if ~isempty(sessionTable)
                    writetable(sessionTable, excelPath);
                    fprintf('Excel文件导出成功: %s\n', excelPath);
                end
            catch ME
                warning('Excel文件导出失败: %s', ME.message);
            end
        end
        
        function cleanup(obj)
            % 清理资源
            if ~isempty(obj.csvFileHandle) && obj.csvFileHandle > 0
                fclose(obj.csvFileHandle);
                obj.csvFileHandle = [];
            end
            
            fprintf('数据记录器清理完成\n');
        end
        
        % Getter方法
        function path = getSessionPath(obj)
            path = obj.sessionPath;
        end
        
        function count = getTrialCount(obj)
            count = obj.trialCounter;
        end
        
        function data = getSessionData(obj)
            data = obj.sessionData;
        end
    end
end