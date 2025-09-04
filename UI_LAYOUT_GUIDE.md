# TaskTrainApp UI布局调整指南

## 概述

TaskTrainApp使用MATLAB App Designer的GridLayout进行UI布局管理。本指南详细说明如何调整UI布局参数，帮助开发者自定义界面。

## 主要布局结构

### 1. 主网格布局 (MainGrid)

**位置：** `TaskTrainApp.m` 第156-162行

```matlab
app.MainGrid = uigridlayout(app.UIFigure);
app.MainGrid.ColumnWidth = {'1.5x', '1.5x', '1x', '1x'};
app.MainGrid.RowHeight = {60, 80, '2x', '1x', '1x', '1x', 80};
app.MainGrid.Padding = [10 10 10 10];
app.MainGrid.RowSpacing = 10;
app.MainGrid.ColumnSpacing = 10;
```

**参数说明：**
- `ColumnWidth`: 控制4列的宽度比例
  - `'1.5x', '1.5x', '1x', '1x'` = 列宽比例为1.5:1.5:1:1
- `RowHeight`: 控制7行的高度
  - `60, 80` = 固定像素高度
  - `'2x', '1x', '1x', '1x'` = 可变高度比例
  - `80` = 底部控制栏固定高度
- `Padding`: 主网格边距 `[左 右 上 下]`
- `RowSpacing/ColumnSpacing`: 行间距和列间距

### 2. 各面板布局位置

当前布局安排（7行×4列）：

| 行 | 列1-4 | 描述 |
|----|-------|------|
| 1 | Session Information | 会话信息面板 |
| 2 | Current Status (列1-2) + LED Indicators (列3-4) | 状态显示和LED指示器 |
| 3 | Recent Trial Results | 试次结果显示 |
| 4 | Current Parameters (列3-4) | 当前参数显示 |
| 5 | Shaping Options (列1) + Sequence Options (列2) + Edit Parameters (列3-4) | 模式选项和参数编辑 |
| 6 | Statistics (列1-2) + Edit Parameters (列3-4) | 统计信息和参数编辑 |
| 7 | Control Panel | 控制按钮 |

## 详细调整参数

### 3. Session Information Panel (第1行)

**创建函数：** `createSessionPanel()` (第223行)

**布局设置：**
```matlab
app.SessionPanel.Layout.Row = 1;
app.SessionPanel.Layout.Column = [1 4];  % 跨越所有4列
```

**内部网格：**
```matlab
app.SessionGrid.ColumnWidth = {80, 150, 80, 150, 80, 150};  % 6列宽度
app.SessionGrid.RowHeight = {'1x'};  % 1行
```

### 4. Current Status Panel (第2行, 列1-2)

**创建函数：** `createStatusPanel()` (第268行)

**布局设置：**
```matlab
app.StatusPanel.Layout.Row = 2;
app.StatusPanel.Layout.Column = [1 2];  % 占用前2列
```

**内部网格：**
```matlab
app.StatusGrid.ColumnWidth = {'1x', '1x', '1x'};  # 3个状态显示等宽
app.StatusGrid.RowHeight = {'1x'};
```

### 5. LED Indicators Panel (第2行, 列3-4)

**创建函数：** `createLEDPanel()` (第305行)

**布局设置：**
```matlab
app.LEDPanel.Layout.Row = 2;
app.LEDPanel.Layout.Column = [3 4];  % 占用后2列
```

**关键LED布局参数：**
```matlab
D = 36;  % LED圆形大小（像素）
app.LEDGrid.Padding = [4 6 4 6];  % LED面板内边距
app.LEDGrid.RowSpacing = 2;       # 行间距
app.LEDGrid.ColumnSpacing = 8;    # 列间距
app.LEDGrid.RowHeight = {D, 16};  # LED行高度和标签行高度
app.LEDGrid.ColumnWidth = {D, D, D, D};  # 4个LED列宽
```

### 6. Recent Trial Results Panel (第3行)

**创建函数：** `createResultsPanel()` (第365行)

**布局设置：**
```matlab
app.ResultsPanel.Layout.Row = 3;
app.ResultsPanel.Layout.Column = [1 4];  % 跨越所有列
```

**结果显示参数（类属性）：**
```matlab
resultSquarePx = 10;   % 方块边长像素（第134行）
resultGapPx = 2;       % 方块间隙像素（第135行）
resultGridCols = 20;   % 每行方块数量（第105行）
resultGridPad = 0.12;  % 单元格内边距比例（第106行）
```

### 7. Current Parameters Panel (第4行, 列3-4)

**创建函数：** `createParamsPanel()` (第434行)

**布局设置：**
```matlab
app.ParamsPanel.Layout.Row = 4;
app.ParamsPanel.Layout.Column = [3 4];
```

### 8. Mode Options Panels (第5行)

#### Shaping Mode Options (列1)
**创建函数：** `createModeOptionsPanel()` (第617行)

**布局设置：**
```matlab
app.ShapingOptionsPanel.Layout.Row = 5;
app.ShapingOptionsPanel.Layout.Column = 1;
```

**内部网格：**
```matlab
app.ShapingOptionsGrid.ColumnWidth = {'1x', '1x'};  % 2列等宽
app.ShapingOptionsGrid.RowHeight = {30, 30};        % 2行固定高度
```

#### Sequence Mode Options (列2)
```matlab
app.SequenceOptionsPanel.Layout.Row = 5;
app.SequenceOptionsPanel.Layout.Column = 2;
```

### 9. Edit Parameters Panel (第5-6行, 列3-4)

**创建函数：** `createEditParamsPanel()` (第458行)

**布局设置：**
```matlab
app.EditParamsPanel.Layout.Row = [5 6];  % 跨越2行
app.EditParamsPanel.Layout.Column = [3 4];  # 跨越2列
```

**内部网格（4列布局）：**
```matlab
app.EditParamsGrid.ColumnWidth = {120, 80, 120, 80};  % 标签宽，输入窄
app.EditParamsGrid.RowHeight = repmat({25}, 1, 7);    % 7行，每行25px
app.EditParamsGrid.Padding = [5 5 5 5];
app.EditParamsGrid.RowSpacing = 3;
app.EditParamsGrid.ColumnSpacing = 5;
```

### 10. Statistics Panel (第6行, 列1-2)

**创建函数：** `createStatsPanel()` (第402行)

**布局设置：**
```matlab
app.StatsPanel.Layout.Row = 6;
app.StatsPanel.Layout.Column = [1 2];
```

### 11. Control Panel (第7行)

**创建函数：** `createControlPanel()` (第686行)

**布局设置：**
```matlab
app.ControlPanel.Layout.Row = 7;
app.ControlPanel.Layout.Column = [1 4];  % 跨越所有列
```

**内部网格：**
```matlab
app.ControlGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};  % 5个按钮等宽
app.ControlGrid.RowHeight = {'1x'};
```

## 常用调整操作

### 调整面板大小

1. **改变列宽比例：**
```matlab
app.MainGrid.ColumnWidth = {'2x', '1x', '1x', '1x'};  % 第1列更宽
```

2. **改变行高：**
```matlab
app.MainGrid.RowHeight = {60, 80, '3x', '1x', '1x', '1x', 60};  % Results更高，Control更矮
```

### 调整面板位置

**移动面板到不同行/列：**
```matlab
app.StatsPanel.Layout.Row = 4;      % 移动到第4行
app.StatsPanel.Layout.Column = [1 3];  % 跨越列1-3
```

### 调整间距和边距

**整体间距：**
```matlab
app.MainGrid.Padding = [15 15 15 15];    % 增大外边距
app.MainGrid.RowSpacing = 15;            % 增大行间距  
app.MainGrid.ColumnSpacing = 15;         # 增大列间距
```

**特定面板内边距：**
```matlab
app.EditParamsGrid.Padding = [10 10 10 10];      % 编辑面板内边距
app.EditParamsGrid.RowSpacing = 5;               # 编辑面板行间距
app.EditParamsGrid.ColumnSpacing = 8;            # 编辑面板列间距
```

## 结果显示自定义

### 调整方块大小和密度

**在类属性部分（第134-135行）：**
```matlab
resultSquarePx = 8;    % 更小的方块
resultGapPx = 1;       # 更紧密的间距
```

**在updateResultsDisplay函数中（第1246-1247行）：**
```matlab
s = max(2, round(app.resultSquarePx)); % 最小2px
g = max(0, round(app.resultGapPx));    # 最小0px间距
```

## 调试技巧

### 查看当前布局

1. 在MATLAB命令窗口运行：
```matlab
app = gui.TaskTrainApp;
app.MainGrid.ColumnWidth
app.MainGrid.RowHeight
```

2. 查看面板位置：
```matlab
app.StatsPanel.Layout.Row
app.StatsPanel.Layout.Column  
```

### 实时调整

在应用运行时，可以通过命令窗口实时调整：
```matlab
app.MainGrid.RowHeight{3} = '3x';  % 让第3行更高
app.StatsPanel.Layout.Column = [1 3];  % 让统计面板跨3列
```

## 注意事项

1. **行列索引从1开始**
2. **跨越多行/列用数组表示：** `[起始, 结束]`
3. **固定大小用数字，比例大小用字符串** (如 `'2x'`)
4. **修改后需要重启应用才能看到效果**
5. **确保所有面板都有合理的行列分配，避免重叠**

## 常见问题

**Q: 面板不显示或重叠？**
A: 检查Layout.Row和Layout.Column设置，确保没有冲突且在网格范围内

**Q: 界面太挤或太松？**  
A: 调整MainGrid的RowSpacing、ColumnSpacing和Padding参数

**Q: 某个面板太小？**
A: 增大对应行/列的尺寸，或让面板跨越更多行/列

**Q: 按钮或控件排列不整齐？**
A: 检查面板内部网格的ColumnWidth和RowHeight设置

通过这些参数的灵活调整，可以实现各种UI布局需求。建议在修改前备份原始代码，并逐步调试验证效果。