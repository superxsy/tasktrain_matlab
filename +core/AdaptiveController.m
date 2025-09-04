classdef AdaptiveController < handle
    % 自适应控制器
    % 根据动物的表现动态调整实验参数
    
    properties (Access = private)
        adjustmentHistory = []  % 调整历史记录
        lastAdjustmentTrial = 0 % 上次调整的试次
        minimumTrialsBetweenAdjustments = 10  % 调整之间的最小试次间隔
    end
    
    events
        ParameterAdjusted   % 参数调整事件
    end
    
    methods
        function obj = AdaptiveController()
            % 构造函数
            obj.adjustmentHistory = [];
        end
        
        function applyAdaptiveAdjustments(obj, trialResults, config)
            % 应用自适应调整
            if ~config.adaptive_enabled
                return;
            end
            
            currentTrial = length(trialResults);
            
            % 检查是否满足调整条件
            if ~obj.shouldMakeAdjustment(currentTrial, config)
                return;
            end
            
            % 计算评估窗口内的表现
            performance = obj.calculatePerformance(trialResults, config);
            
            % 根据表现调整参数
            adjustmentMade = obj.adjustParameters(performance, config);
            
            if adjustmentMade
                obj.lastAdjustmentTrial = currentTrial;
                obj.recordAdjustment(currentTrial, performance, config);
                
                % 通知参数调整
                notify(obj, 'ParameterAdjusted', ...
                       core.ParameterAdjustedEventData(performance, config));
            end
        end
        
        function shouldAdjust = shouldMakeAdjustment(obj, currentTrial, config)
            % 判断是否应该进行调整
            shouldAdjust = false;
            
            % 条件1：有足够的试次进行评估
            if currentTrial < config.adaptive_window
                return;
            end
            
            % 条件2：距离上次调整有足够的间隔
            if (currentTrial - obj.lastAdjustmentTrial) < obj.minimumTrialsBetweenAdjustments
                return;
            end
            
            shouldAdjust = true;
        end
        
        function performance = calculatePerformance(obj, trialResults, config)
            % 计算性能指标
            windowSize = config.adaptive_window;
            recentResults = trialResults(end-windowSize+1:end);
            
            performance = struct();
            performance.window_size = windowSize;
            performance.total_trials = length(recentResults);
            performance.correct_trials = sum(recentResults == 0);
            performance.accuracy = performance.correct_trials / performance.total_trials;
            
            % 错误类型分析
            performance.no_press_errors = sum(recentResults == 1);
            performance.wrong_button_errors = sum(recentResults == 2);
            performance.hold_too_long_errors = sum(recentResults == 3);
            performance.premature_press_errors = sum(recentResults == 4);
            
            % 错误率
            performance.no_press_rate = performance.no_press_errors / performance.total_trials;
            performance.wrong_button_rate = performance.wrong_button_errors / performance.total_trials;
            performance.hold_too_long_rate = performance.hold_too_long_errors / performance.total_trials;
            performance.premature_press_rate = performance.premature_press_errors / performance.total_trials;
            
            % 趋势分析（比较前半窗口和后半窗口）
            if windowSize >= 10
                halfWindow = floor(windowSize / 2);
                firstHalf = recentResults(1:halfWindow);
                secondHalf = recentResults(end-halfWindow+1:end);
                
                firstHalfAccuracy = sum(firstHalf == 0) / length(firstHalf);
                secondHalfAccuracy = sum(secondHalf == 0) / length(secondHalf);
                
                performance.trend = secondHalfAccuracy - firstHalfAccuracy;
                performance.improving = performance.trend > 0.1;  % 提高10%以上认为是改善
                performance.declining = performance.trend < -0.1;  % 下降10%以上认为是退步
            else
                performance.trend = 0;
                performance.improving = false;
                performance.declining = false;
            end
            
            % 一致性分析（连续正确的最大长度）
            performance.max_consecutive_correct = obj.calculateMaxConsecutive(recentResults, 0);
            performance.consistency_score = performance.max_consecutive_correct / performance.total_trials;
        end
        
        function adjustmentMade = adjustParameters(obj, performance, config)
            % 根据表现调整参数
            adjustmentMade = false;
            
            % 主要调整策略
            if performance.accuracy >= config.adaptive_threshold_high
                % 表现良好，增加难度
                adjustmentMade = obj.increaseDifficulty(performance, config);
                
            elseif performance.accuracy <= config.adaptive_threshold_low
                % 表现不佳，降低难度
                adjustmentMade = obj.decreaseDifficulty(performance, config);
                
            else
                % 表现中等，根据错误类型进行微调
                adjustmentMade = obj.finetuneParameters(performance, config);
            end
        end
        
        function adjusted = increaseDifficulty(obj, performance, config)
            % 增加难度
            adjusted = false;
            
            fprintf('表现良好 (%.1f%%)，增加难度\n', performance.accuracy * 100);
            
            % 策略1：缩短等待时间
            waitParams = {'wait_L1', 'wait_L2', 'wait_L3'};
            for i = 1:length(waitParams)
                currentVal = config.(waitParams{i});
                newVal = max(config.min_wait, currentVal - config.adaptive_step);
                
                if newVal < currentVal
                    fprintf('  %s: %.2f -> %.2f\n', waitParams{i}, currentVal, newVal);
                    config.(waitParams{i}) = newVal;
                    adjusted = true;
                end
            end
            
            % 策略2：如果等待时间已经最小，考虑缩短松开窗口
            if ~adjusted && config.release_window > 0.5
                newReleaseWindow = max(0.5, config.release_window - 0.1);
                if newReleaseWindow < config.release_window
                    fprintf('  release_window: %.2f -> %.2f\n', config.release_window, newReleaseWindow);
                    config.release_window = newReleaseWindow;
                    adjusted = true;
                end
            end
            
            % 策略3：缩短间隔时间（更困难的时序控制）
            if ~adjusted
                intervalParams = {'I1', 'I2'};
                for i = 1:length(intervalParams)
                    currentVal = config.(intervalParams{i});
                    newVal = max(0.1, currentVal - 0.05);
                    
                    if newVal < currentVal
                        fprintf('  %s: %.2f -> %.2f\n', intervalParams{i}, currentVal, newVal);
                        config.(intervalParams{i}) = newVal;
                        adjusted = true;
                        break;
                    end
                end
            end
        end
        
        function adjusted = decreaseDifficulty(obj, performance, config)
            % 降低难度
            adjusted = false;
            
            fprintf('表现不佳 (%.1f%%)，降低难度\n', performance.accuracy * 100);
            
            % 根据主要错误类型选择调整策略
            if performance.no_press_rate > 0.3
                % 主要是未按压错误，延长等待时间
                adjusted = obj.increaseWaitTimes(config, '未按压错误过多');
                
            elseif performance.hold_too_long_rate > 0.2
                % 主要是按住过久错误，延长松开窗口
                newReleaseWindow = min(3.0, config.release_window + 0.2);
                if newReleaseWindow > config.release_window
                    fprintf('  release_window: %.2f -> %.2f (按住过久错误)\n', ...
                            config.release_window, newReleaseWindow);
                    config.release_window = newReleaseWindow;
                    adjusted = true;
                end
                
            elseif performance.premature_press_rate > 0.2
                % 主要是过早按压错误，延长间隔时间
                intervalParams = {'I1', 'I2'};
                for i = 1:length(intervalParams)
                    currentVal = config.(intervalParams{i});
                    newVal = min(2.0, currentVal + 0.1);
                    
                    if newVal > currentVal
                        fprintf('  %s: %.2f -> %.2f (过早按压错误)\n', ...
                                intervalParams{i}, currentVal, newVal);
                        config.(intervalParams{i}) = newVal;
                        adjusted = true;
                        break;
                    end
                end
                
            else
                % 一般性表现不佳，延长等待时间
                adjusted = obj.increaseWaitTimes(config, '一般性表现不佳');
            end
        end
        
        function adjusted = increaseWaitTimes(obj, config, reason)
            % 延长等待时间
            adjusted = false;
            
            waitParams = {'wait_L1', 'wait_L2', 'wait_L3'};
            for i = 1:length(waitParams)
                currentVal = config.(waitParams{i});
                newVal = min(config.max_wait, currentVal + config.adaptive_step);
                
                if newVal > currentVal
                    fprintf('  %s: %.2f -> %.2f (%s)\n', waitParams{i}, currentVal, newVal, reason);
                    config.(waitParams{i}) = newVal;
                    adjusted = true;
                end
            end
        end
        
        function adjusted = finetuneParameters(obj, performance, config)
            % 中等表现的微调
            adjusted = false;
            
            % 基于趋势进行微调
            if performance.improving
                % 表现在改善，轻微增加难度
                waitParams = {'wait_L1', 'wait_L2', 'wait_L3'};
                adjustmentSize = config.adaptive_step * 0.5;  % 较小的调整
                
                for i = 1:length(waitParams)
                    currentVal = config.(waitParams{i});
                    newVal = max(config.min_wait, currentVal - adjustmentSize);
                    
                    if newVal < currentVal
                        fprintf('  %s: %.2f -> %.2f (改善趋势，微调)\n', ...
                                waitParams{i}, currentVal, newVal);
                        config.(waitParams{i}) = newVal;
                        adjusted = true;
                        break;  % 只调整一个参数
                    end
                end
                
            elseif performance.declining
                % 表现在下降，轻微降低难度
                waitParams = {'wait_L1', 'wait_L2', 'wait_L3'};
                adjustmentSize = config.adaptive_step * 0.5;
                
                for i = 1:length(waitParams)
                    currentVal = config.(waitParams{i});
                    newVal = min(config.max_wait, currentVal + adjustmentSize);
                    
                    if newVal > currentVal
                        fprintf('  %s: %.2f -> %.2f (下降趋势，微调)\n', ...
                                waitParams{i}, currentVal, newVal);
                        config.(waitParams{i}) = newVal;
                        adjusted = true;
                        break;
                    end
                end
            end
            
            % 如果没有明显趋势，检查是否需要特定的微调
            if ~adjusted
                adjusted = obj.addressSpecificIssues(performance, config);
            end
        end
        
        function adjusted = addressSpecificIssues(obj, performance, config)
            % 解决特定问题
            adjusted = false;
            
            % 如果一致性较差（经常断断续续），轻微降低难度
            if performance.consistency_score < 0.3 && performance.accuracy > 0.6
                waitParams = {'wait_L1', 'wait_L2', 'wait_L3'};
                currentVal = config.(waitParams{1});  % 只调整第一个参数
                newVal = min(config.max_wait, currentVal + config.adaptive_step * 0.3);
                
                if newVal > currentVal
                    fprintf('  %s: %.2f -> %.2f (提高一致性)\n', ...
                            waitParams{1}, currentVal, newVal);
                    config.(waitParams{1}) = newVal;
                    adjusted = true;
                end
            end
        end
        
        function maxConsecutive = calculateMaxConsecutive(obj, results, targetValue)
            % 计算最大连续目标值的数量
            maxConsecutive = 0;
            currentConsecutive = 0;
            
            for i = 1:length(results)
                if results(i) == targetValue
                    currentConsecutive = currentConsecutive + 1;
                    maxConsecutive = max(maxConsecutive, currentConsecutive);
                else
                    currentConsecutive = 0;
                end
            end
        end
        
        function recordAdjustment(obj, trialNumber, performance, config)
            % 记录调整历史
            adjustment = struct();
            adjustment.trial_number = trialNumber;
            adjustment.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            adjustment.performance = performance;
            adjustment.config_after = config.toStruct();
            
            obj.adjustmentHistory(end+1) = adjustment;
            
            fprintf('参数调整记录：试次 %d，正确率 %.1f%%\n', ...
                    trialNumber, performance.accuracy * 100);
        end
        
        function saveAdjustmentHistory(obj, filepath)
            % 保存调整历史
            try
                adjustmentData = struct();
                adjustmentData.adjustments = obj.adjustmentHistory;
                adjustmentData.total_adjustments = length(obj.adjustmentHistory);
                adjustmentData.export_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                
                jsonStr = jsonencode(adjustmentData, 'PrettyPrint', true);
                fid = fopen(filepath, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                
                fprintf('自适应调整历史保存成功: %s\n', filepath);
            catch ME
                warning('自适应调整历史保存失败: %s', ME.message);
            end
        end
        
        function summary = getAdjustmentSummary(obj)
            % 获取调整汇总
            summary = struct();
            summary.total_adjustments = length(obj.adjustmentHistory);
            
            if summary.total_adjustments > 0
                % 提取所有正确率
                accuracies = zeros(1, summary.total_adjustments);
                for i = 1:summary.total_adjustments
                    accuracies(i) = obj.adjustmentHistory(i).performance.accuracy;
                end
                
                summary.initial_accuracy = accuracies(1);
                summary.final_accuracy = accuracies(end);
                summary.improvement = summary.final_accuracy - summary.initial_accuracy;
                summary.average_accuracy = mean(accuracies);
                summary.accuracy_trend = accuracies;
                
                % 调整类型统计
                summary.difficulty_increases = 0;
                summary.difficulty_decreases = 0;
                
                for i = 1:summary.total_adjustments
                    if obj.adjustmentHistory(i).performance.accuracy >= 0.85
                        summary.difficulty_increases = summary.difficulty_increases + 1;
                    elseif obj.adjustmentHistory(i).performance.accuracy <= 0.60
                        summary.difficulty_decreases = summary.difficulty_decreases + 1;
                    end
                end
            else
                summary.initial_accuracy = 0;
                summary.final_accuracy = 0;
                summary.improvement = 0;
                summary.average_accuracy = 0;
                summary.accuracy_trend = [];
                summary.difficulty_increases = 0;
                summary.difficulty_decreases = 0;
            end
        end
        
        function printAdjustmentSummary(obj)
            % 打印调整汇总
            summary = obj.getAdjustmentSummary();
            
            fprintf('\n=== 自适应调整汇总 ===\n');
            fprintf('总调整次数: %d\n', summary.total_adjustments);
            
            if summary.total_adjustments > 0
                fprintf('初始正确率: %.1f%%\n', summary.initial_accuracy * 100);
                fprintf('最终正确率: %.1f%%\n', summary.final_accuracy * 100);
                fprintf('平均正确率: %.1f%%\n', summary.average_accuracy * 100);
                fprintf('整体改善: %.1f%%\n', summary.improvement * 100);
                fprintf('增加难度次数: %d\n', summary.difficulty_increases);
                fprintf('降低难度次数: %d\n', summary.difficulty_decreases);
            else
                fprintf('未进行任何调整\n');
            end
            fprintf('=====================\n');
        end
        
        function reset(obj)
            % 重置控制器
            obj.adjustmentHistory = [];
            obj.lastAdjustmentTrial = 0;
            fprintf('自适应控制器已重置\n');
        end
        
        % Getter方法
        function history = getAdjustmentHistory(obj)
            history = obj.adjustmentHistory;
        end
        
        function count = getAdjustmentCount(obj)
            count = length(obj.adjustmentHistory);
        end
        
        function trial = getLastAdjustmentTrial(obj)
            trial = obj.lastAdjustmentTrial;
        end
    end
end