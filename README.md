# 三键序列小鼠训练任务 (MATLAB版本)

基于MATLAB开发的专业行为学实验平台，支持Arduino Due硬件控制，提供高精度时序控制和数据记录功能。

## 功能特点

- ✅ **双模式支持**: Sequence-3序列训练和Shaping-1塑形训练
- ✅ **硬件集成**: Arduino Due控制LED、按钮和电磁阀
- ✅ **模拟模式**: 键盘模拟，无需硬件即可测试
- ✅ **高精度时序**: 毫秒级时间控制和事件记录
- ✅ **实时数据记录**: JSON和CSV格式数据保存
- ✅ **自适应算法**: 根据表现动态调整难度
- ✅ **直观界面**: 现代化GUI，实时状态显示
- ✅ **数据分析**: 内置统计分析和可视化

## 系统要求

### 软件要求
- MATLAB R2019b或更高版本
- MATLAB Support Package for Arduino Hardware (硬件模式)
- Instrument Control Toolbox (硬件模式)

### 硬件要求 (可选)
- Arduino Due开发板
- LED指示灯 × 3
- 光电开关按钮 × 3
- 电磁阀 × 1

## 快速开始

### 1. 安装配置

```matlab
% 在MATLAB命令窗口中运行
cd('path/to/tasktrain_matlab')  % 切换到项目目录
TaskTrain()                     % 启动程序
```

### 2. 硬件连接 (可选)

如果使用Arduino硬件，请按以下引脚连接:

| 功能 | Arduino引脚 | 说明 |
|------|-------------|------|
| LED1 | D22 | 第一个LED指示灯 |
| LED2 | D23 | 第二个LED指示灯 |
| LED3 | D24 | 第三个LED指示灯 |
| 按钮1 | D30 | 第一个光电开关 |
| 按钮2 | D31 | 第二个光电开关 |
| 按钮3 | D32 | 第三个光电开关 |
| 电磁阀 | D26 | 奖励给予装置 |

### 3. 模拟模式

如果没有Arduino硬件，程序会自动使用键盘模拟:
- **Q键** - 按钮1
- **W键** - 按钮2  
- **E键** - 按钮3

## 使用说明

### 界面布局

1. **会话信息区**: 设置被试ID、会话标签和训练模式
2. **状态显示区**: 实时显示当前状态、倒计时和试次进度
3. **LED指示器**: 同步显示硬件LED状态
4. **结果条带**: 滚动显示最近30个试次结果
5. **统计面板**: 实时统计正确率和错误类型
6. **参数显示**: 显示当前时序参数
7. **控制按钮**: 开始/暂停、重置、配置等功能

### 快捷键

- **空格键** - 开始/暂停实验
- **R键** - 重置会话
- **C键** - 打开配置对话框
- **H键** - 显示帮助信息
- **Tab键** - 切换训练模式

### 训练模式

#### Sequence-3模式
完整的三键序列训练:
1. ITI (试次间隔)
2. L1_WAIT (等待按压按钮1)
3. I1 (按钮1和2之间的间隔)
4. L2_WAIT (等待按压按钮2)
5. I2 (按钮2和3之间的间隔)
6. L3_WAIT (等待按压按钮3)
7. REWARD (奖励给予)

#### Shaping-1模式
单按钮塑形训练:
1. ITI (试次间隔)
2. SHAPING_WAIT (等待按压指定按钮)
3. REWARD (奖励给予)

### 错误类型

- **0 - Correct**: 正确完成序列
- **1 - No Press**: 等待窗口内未按压
- **2 - Wrong Button**: 按错按钮
- **3 - Hold Too Long**: 按住时间超过松开窗口
- **4 - Premature Press**: 在间隔期过早按压

## 数据文件

### 文件结构
```
data/
├── M001/                    # 被试ID
│   └── 20240101_120000/     # 会话标签
│       ├── trial_0001.json  # 试次详细数据
│       ├── trial_0002.json
│       ├── ...
│       ├── session_summary.csv      # 会话汇总CSV
│       ├── session_analysis.json    # 会话统计分析
│       └── config_snapshot.json     # 配置快照
```

### 数据字段

#### JSON试次数据
- `subject_id`: 被试ID
- `session_label`: 会话标签
- `trial_index`: 试次索引
- `mode`: 训练模式
- `events[]`: 详细事件列表
- `stage_timestamps{}`: 各阶段时间戳
- `press_release_times{}`: 按键松开时间
- `result_code`: 结果代码
- `result_text`: 结果描述

#### CSV汇总数据
包含所有试次的关键指标，便于进一步分析。

## 配置参数

### 时序参数
- `wait_L1/L2/L3`: LED等待时间 (秒)
- `I1/I2`: 间隔时间 (秒)
- `release_window`: 松开窗口时间 (秒)
- `R_duration`: 奖励持续时间 (秒)

### ITI参数
- `ITI_fixed_correct`: 正确试次固定ITI (秒)
- `ITI_rand_correct`: 正确试次随机ITI (秒)
- `ITI_fixed_error`: 错误试次固定ITI (秒)
- `ITI_rand_error`: 错误试次随机ITI (秒)

### 自适应参数
- `adaptive_enabled`: 是否启用自适应
- `adaptive_window`: 评估窗口大小
- `adaptive_threshold_high/low`: 调整阈值
- `adaptive_step`: 调整步长

## 自适应算法

系统可根据动物表现自动调整参数:

- **表现良好** (>85%): 缩短等待时间，增加难度
- **表现不佳** (<60%): 延长等待时间，降低难度
- **中等表现**: 根据错误类型和趋势进行微调

## 故障排除

### 常见问题

1. **Arduino连接失败**
   - 检查USB连接
   - 确认Arduino驱动已安装
   - 检查串口权限
   - 尝试重新插拔USB

2. **界面显示异常**
   - 检查显示器分辨率和DPI设置
   - 确保MATLAB App Designer可用
   - 重启MATLAB

3. **性能问题**
   - 关闭其他MATLAB程序
   - 降低UI刷新率
   - 检查系统资源使用

4. **数据保存失败**
   - 检查磁盘空间
   - 确认目录写权限
   - 检查文件路径中的特殊字符

### 日志文件

程序运行时会在MATLAB命令窗口输出详细日志，包括:
- 硬件连接状态
- 试次进度和结果
- 参数调整信息
- 错误和警告信息

## 技术架构

### 核心组件
- `TaskStateMachine`: 状态机控制逻辑
- `Config`: 配置管理
- `TrialLogger`: 数据记录
- `AdaptiveController`: 自适应算法
- `IOBackend`: 硬件抽象层

### IO后端
- `ArduinoBackend`: Arduino硬件控制
- `SimKeyboardBackend`: 键盘模拟

## 许可证

本项目采用MIT许可证，详情请见LICENSE文件。

## 支持

如需技术支持或报告问题，请联系:
- 邮箱: support@example.com
- 文档: https://docs.example.com

## 更新日志

### v1.0 (2024-01-01)
- 初始版本发布
- 完整的Sequence-3和Shaping-1训练模式
- Arduino Due硬件支持
- 自适应算法实现
- 现代化GUI界面