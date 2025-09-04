classdef Config < handle
    % 配置管理类
    % 集中管理所有实验参数和配置
    
    properties
        % 任务模式
        mode = 'sequence3'  % 'sequence3' | 'shaping1'
        shaping_led = 1
        
        % Random mode settings
        shaping_random_mode = false  % Whether to randomize LED in shaping mode
        sequence_random_mode = false  % Whether to randomize sequence order
        custom_sequence = [1, 2, 3]  % Custom sequence order for sequence mode
        
        % 时序参数（秒）
        wait_L1 = 3.0
        wait_L2 = 3.0
        wait_L3 = 3.0
        I1 = 0.5
        I2 = 0.5
        R_duration = 0.3
        release_window = 1.0
        
        % ITI参数
        ITI_fixed_correct = 1.0
        ITI_rand_correct = 1.0
        ITI_fixed_error = 2.0
        ITI_rand_error = 1.0
        
        % 会话参数
        max_trials = 500
        subject_id = 'M001'
        session_label = ''
        
        % 自适应参数
        adaptive_enabled = false
        adaptive_window = 20
        adaptive_threshold_high = 0.85
        adaptive_threshold_low = 0.60
        adaptive_step = 0.1
        min_wait = 1.0
        max_wait = 5.0
        
        % 硬件参数
        arduino_port = ''  % 空字符串表示自动检测
        led_pins = [22, 23, 24]
        button_pins = [30, 31, 32]
        valve_pin = 26
        debounce_time = 0.01
        
        % 系统参数
        update_frequency = 100  % Hz
        ui_refresh_rate = 30    % FPS
        simulation_mode = false  % 是否使用模拟模式
    end
    
    methods
        function obj = Config(varargin)
            % 构造函数，可选的配置文件路径
            if nargin > 0
                obj.loadFromFile(varargin{1});
            end
        end
        
        function loadFromFile(obj, filename)
            % 从JSON文件加载配置
            try
                if exist(filename, 'file')
                    data = jsondecode(fileread(filename));
                    fields = fieldnames(data);
                    for i = 1:length(fields)
                        if isprop(obj, fields{i})
                            obj.(fields{i}) = data.(fields{i});
                        end
                    end
                    fprintf('配置文件加载成功: %s\n', filename);
                else
                    fprintf('配置文件不存在，使用默认配置: %s\n', filename);
                end
            catch ME
                fprintf('配置文件加载失败: %s\n', ME.message);
                fprintf('使用默认配置\n');
            end
        end
        
        function saveToFile(obj, filename)
            % 保存配置到JSON文件
            try
                configStruct = obj.toStruct();
                jsonStr = jsonencode(configStruct, 'PrettyPrint', true);
                fid = fopen(filename, 'w');
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                fprintf('配置文件保存成功: %s\n', filename);
            catch ME
                fprintf('配置文件保存失败: %s\n', ME.message);
            end
        end
        
        function s = toStruct(obj)
            % 转换为结构体
            props = properties(obj);
            s = struct();
            for i = 1:length(props)
                s.(props{i}) = obj.(props{i});
            end
        end
        
        function validateConfig(obj)
            % 验证配置参数的合理性
            errors = {};
            
            % 检查时序参数
            if obj.wait_L1 <= 0 || obj.wait_L2 <= 0 || obj.wait_L3 <= 0
                errors{end+1} = '等待时间必须大于0';
            end
            
            if obj.I1 <= 0 || obj.I2 <= 0
                errors{end+1} = '间隔时间必须大于0';
            end
            
            if obj.release_window <= 0
                errors{end+1} = '松开窗口时间必须大于0';
            end
            
            % 检查自适应参数
            if obj.adaptive_enabled
                if obj.adaptive_window <= 0
                    errors{end+1} = '自适应窗口大小必须大于0';
                end
                
                if obj.adaptive_threshold_high <= obj.adaptive_threshold_low
                    errors{end+1} = '自适应高阈值必须大于低阈值';
                end
                
                if obj.min_wait >= obj.max_wait
                    errors{end+1} = '最小等待时间必须小于最大等待时间';
                end
            end
            
            % 检查会话参数
            if obj.max_trials <= 0
                errors{end+1} = '最大试次数必须大于0';
            end
            
            if isempty(obj.subject_id)
                errors{end+1} = '被试ID不能为空';
            end
            
            % 输出验证结果
            if isempty(errors)
                fprintf('配置验证通过\n');
            else
                fprintf('配置验证失败:\n');
                for i = 1:length(errors)
                    fprintf('  - %s\n', errors{i});
                end
                error('配置验证失败');
            end
        end
        
        function iti = calculateITI(obj, isCorrect)
            % 计算ITI时间
            if isCorrect
                fixed = obj.ITI_fixed_correct;
                random = obj.ITI_rand_correct;
            else
                fixed = obj.ITI_fixed_error;
                random = obj.ITI_rand_error;
            end
            iti = fixed + random * rand();
        end
        
        function generateSessionLabel(obj)
            % 生成会话标签
            if isempty(obj.session_label)
                obj.session_label = datestr(now, 'yyyymmdd_HHMMSS');
            end
        end
    end
end