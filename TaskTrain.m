function TaskTrain()
% TASKTRAIN 三键序列小鼠训练任务主程序
%
% 使用方法:
%   TaskTrain() - 启动图形界面
%
% 功能特点:
%   - 支持Sequence-3和Shaping-1两种训练模式
%   - Arduino Due硬件控制或键盘模拟
%   - 实时数据记录和分析
%   - 自适应难度调整
%   - 直观的图形用户界面
%
% 硬件要求:
%   - Arduino Due开发板（可选）
%   - LED指示灯 x3
%   - 光电开关按钮 x3  
%   - 电磁阀 x1
%
% 软件要求:
%   - MATLAB R2019b或更高版本
%   - MATLAB Support Package for Arduino Hardware（硬件模式）
%   - Instrument Control Toolbox（硬件模式）
%
% 作者: MATLAB工程师
% 版本: 1.0
% 日期: 2024年1月

    try
        fprintf('=== 三键序列小鼠训练任务 ===\n');
        fprintf('版本: 1.0\n');
        fprintf('启动时间: %s\n', datestr(now));
        fprintf('=============================\n\n');
        
        % 检查MATLAB版本
       % checkMATLABVersion();
        
        % 检查依赖工具箱
%        checkDependencies();
        
        % 设置路径
        setupPath();
        
        % 启动GUI应用
        fprintf('启动图形界面...\n');
        app = gui.TaskTrainApp();
        
        % 等待应用关闭
        waitfor(app.UIFigure);
        
        fprintf('\n应用程序已退出\n');
        
    catch ME
        fprintf('启动失败: %s\n', ME.message);
        fprintf('完整错误信息:\n');
        fprintf('%s\n', getReport(ME));
        
        % 显示帮助信息
        showHelp();
    end
end

function checkMATLABVersion()
    % 检查MATLAB版本
    version = version('-release');
    year = str2double(2024);
    
    if year < 2019
        warning('建议使用MATLAB R2019b或更高版本');
    end
    
    fprintf('MATLAB版本: %s\n', version);
end

function checkDependencies()
    % 检查依赖工具箱
    fprintf('检查依赖工具箱...\n');
    
    % 必需的工具箱
    requiredToolboxes = {
        'MATLAB', '基础MATLAB';
    };
    
    % 可选的工具箱（用于硬件控制）
    optionalToolboxes = {
        'MATLAB Support Package for Arduino Hardware', 'Arduino支持包';
        'Instrument Control Toolbox', '仪器控制工具箱';
    };
    
    % 检查必需工具箱
    for i = 1:size(requiredToolboxes, 1)
        toolboxName = requiredToolboxes{i, 1};
        displayName = requiredToolboxes{i, 2};
        
        if license('test', toolboxName)
            fprintf('  ✓ %s\n', displayName);
        else
            error('缺少必需工具箱: %s', displayName);
        end
    end
    
    % 检查可选工具箱
    fprintf('可选工具箱状态:\n');
    for i = 1:size(optionalToolboxes, 1)
        toolboxName = optionalToolboxes{i, 1};
        displayName = optionalToolboxes{i, 2};
        
        if license('test', toolboxName)
            fprintf('  ✓ %s (可用)\n', displayName);
        else
            fprintf('  ✗ %s (不可用，将使用模拟模式)\n', displayName);
        end
    end
    
    fprintf('依赖检查完成\n\n');
end

function setupPath()
    % 设置MATLAB路径
    currentDir = fileparts(mfilename('fullpath'));
    
    % 添加核心模块路径
    addpath(genpath(currentDir));
    
    fprintf('MATLAB路径设置完成\n');
end

function showHelp()
    % 显示帮助信息
    fprintf('\n=== 使用帮助 ===\n');
    fprintf('如果遇到问题，请检查以下事项：\n\n');
    
    fprintf('1. MATLAB版本：\n');
    fprintf('   - 建议使用R2019b或更高版本\n');
    fprintf('   - 确保App Designer可用\n\n');
    
    fprintf('2. 硬件模式要求：\n');
    fprintf('   - 安装"MATLAB Support Package for Arduino Hardware"\n');
    fprintf('   - 连接Arduino Due到USB端口\n');
    fprintf('   - 确保Arduino驱动程序已安装\n\n');
    
    fprintf('3. 模拟模式：\n');
    fprintf('   - 如果没有Arduino硬件，程序会自动使用模拟模式\n');
    fprintf('   - 使用键盘Q、W、E键模拟按钮1、2、3\n\n');
    
    fprintf('4. 数据存储：\n');
    fprintf('   - 数据保存在"data"目录下\n');
    fprintf('   - 按被试ID和会话标签组织\n');
    fprintf('   - 支持JSON和CSV格式导出\n\n');
    
    fprintf('5. 常见问题：\n');
    fprintf('   - 如果Arduino连接失败，检查串口权限\n');
    fprintf('   - 如果UI无法显示，检查显示器DPI设置\n');
    fprintf('   - 如果性能较慢，关闭其他MATLAB程序\n\n');
    
    fprintf('如需更多帮助，请查阅用户手册或联系技术支持\n');
    fprintf('===============\n');
end