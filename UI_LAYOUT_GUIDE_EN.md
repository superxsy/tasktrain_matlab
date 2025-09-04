# TaskTrainApp UI Layout Adjustment Guide

## Overview

This document provides detailed guidance for adjusting the UI layout of TaskTrainApp using MATLAB App Designer's GridLayout system. All interface elements are organized using grid-based layout for responsive design and consistent appearance.

## Main Grid Structure

### Primary Grid Layout
```
MainGrid (6×3)
┌─────────────────┬─────────────────┬─────────────────┐
│ SessionPanel    │ StatusPanel     │ LEDPanel        │ Row 1
├─────────────────┼─────────────────┼─────────────────┤
│ RecentPanel     │ RecentPanel     │ RecentPanel     │ Row 2
├─────────────────┼─────────────────┼─────────────────┤
│ ParamsPanel     │ ParamsPanel     │ ModePanel       │ Row 3
├─────────────────┼─────────────────┼─────────────────┤
│ EditPanel       │ EditPanel       │ EditPanel       │ Row 4
├─────────────────┼─────────────────┼─────────────────┤
│ StatsPanel      │ StatsPanel      │ StatsPanel      │ Row 5
├─────────────────┼─────────────────┼─────────────────┤
│ ControlPanel    │ ControlPanel    │ ControlPanel    │ Row 6
└─────────────────┴─────────────────┴─────────────────┘
```

### Panel Positions
- **Row 1**: Session Information, Current Status, LED Indicators
- **Row 2**: Recent Trial Results (spans all columns)
- **Row 3**: Current Parameters, Mode Options
- **Row 4**: Edit Parameters (spans all columns)
- **Row 5**: Statistics (spans all columns)
- **Row 6**: Control Panel (spans all columns)

## Detailed Adjustment Parameters

### 1. Session Information Panel
**Location**: MainGrid(1,1)
```matlab
% Panel properties
SessionPanel.Layout.Row = 1;
SessionPanel.Layout.Column = 1;

% Internal grid (3×2)
SessionGrid.RowHeight = {'1x', '1x', '1x'};
SessionGrid.ColumnWidth = {'120px', '1x'};

% Component positions
SubjectLabel.Layout.Row = 1; SubjectLabel.Layout.Column = 1;
SubjectField.Layout.Row = 1; SubjectField.Layout.Column = 2;
SessionLabel.Layout.Row = 2; SessionLabel.Layout.Column = 1;
SessionField.Layout.Row = 2; SessionField.Layout.Column = 2;
TrialLabel.Layout.Row = 3; TrialLabel.Layout.Column = 1;
TrialField.Layout.Row = 3; TrialField.Layout.Column = 2;
```

### 2. Current Status Panel
**Location**: MainGrid(1,2)
```matlab
% Panel properties
StatusPanel.Layout.Row = 1;
StatusPanel.Layout.Column = 2;

% Internal grid (2×2)
StatusGrid.RowHeight = {'1x', '1x'};
StatusGrid.ColumnWidth = {'100px', '1x'};

% Component positions
StateLabel.Layout.Row = 1; StateLabel.Layout.Column = 1;
StateDisplay.Layout.Row = 1; StateDisplay.Layout.Column = 2;
TimeLabel.Layout.Row = 2; TimeLabel.Layout.Column = 1;
TimeDisplay.Layout.Row = 2; TimeDisplay.Layout.Column = 2;
```

### 3. LED Indicators Panel
**Location**: MainGrid(1,3)
```matlab
% Panel properties
LEDPanel.Layout.Row = 1;
LEDPanel.Layout.Column = 3;

% Internal grid (1×3)
LEDGrid.RowHeight = {'1x'};
LEDGrid.ColumnWidth = {'1x', '1x', '1x'};

% LED positions
LED1.Layout.Row = 1; LED1.Layout.Column = 1;
LED2.Layout.Row = 1; LED2.Layout.Column = 2;
LED3.Layout.Row = 1; LED3.Layout.Column = 3;

% LED properties
LED_Size = [40, 40];  % Width, Height in pixels
LED_Colors = {
    'off': [0.8, 0.8, 0.8],
    'on': [1.0, 0.0, 0.0],
    'active': [0.0, 1.0, 0.0]
};
```

### 4. Recent Trial Results Panel
**Location**: MainGrid(2,1:3)
```matlab
% Panel properties
RecentPanel.Layout.Row = 2;
RecentPanel.Layout.Column = [1, 3];  % Spans columns 1-3

% Internal grid (1×1)
RecentGrid.RowHeight = {'1x'};
RecentGrid.ColumnWidth = {'1x'};

% Result strip properties
ResultStrip.Layout.Row = 1;
ResultStrip.Layout.Column = 1;
ResultStrip.MaxResults = 50;  % Maximum number of results to display

% Result colors
ResultColors = {
    0: [0.0, 0.8, 0.0],  % Success - Green
    1: [1.0, 0.5, 0.0],  % Early Release - Orange
    2: [1.0, 0.0, 0.0],  % Wrong Button - Red
    3: [0.5, 0.0, 0.5],  % Timeout - Purple
    4: [0.8, 0.8, 0.0]   % ITI Error - Yellow
};
```

### 5. Current Parameters Panel
**Location**: MainGrid(3,1:2)
```matlab
% Panel properties
ParamsPanel.Layout.Row = 3;
ParamsPanel.Layout.Column = [1, 2];  % Spans columns 1-2

% Internal grid (4×4)
ParamsGrid.RowHeight = {'1x', '1x', '1x', '1x'};
ParamsGrid.ColumnWidth = {'120px', '80px', '120px', '80px'};

% Parameter display positions
L1Label.Layout.Row = 1; L1Label.Layout.Column = 1;
L1Value.Layout.Row = 1; L1Value.Layout.Column = 2;
I1Label.Layout.Row = 1; I1Label.Layout.Column = 3;
I1Value.Layout.Row = 1; I1Value.Layout.Column = 4;

L2Label.Layout.Row = 2; L2Label.Layout.Column = 1;
L2Value.Layout.Row = 2; L2Value.Layout.Column = 2;
I2Label.Layout.Row = 2; I2Label.Layout.Column = 3;
I2Value.Layout.Row = 2; I2Value.Layout.Column = 4;

L3Label.Layout.Row = 3; L3Label.Layout.Column = 1;
L3Value.Layout.Row = 3; L3Value.Layout.Column = 2;
RewardLabel.Layout.Row = 3; RewardLabel.Layout.Column = 3;
RewardValue.Layout.Row = 3; RewardValue.Layout.Column = 4;

ITILabel.Layout.Row = 4; ITILabel.Layout.Column = 1;
ITIValue.Layout.Row = 4; ITIValue.Layout.Column = 2;
```

### 6. Mode Options Panel
**Location**: MainGrid(3,3)
```matlab
% Panel properties
ModePanel.Layout.Row = 3;
ModePanel.Layout.Column = 3;

% Internal grid (3×1)
ModeGrid.RowHeight = {'1x', '1x', '1x'};
ModeGrid.ColumnWidth = {'1x'};

% Mode controls
HardwareRadio.Layout.Row = 1; HardwareRadio.Layout.Column = 1;
SimulationRadio.Layout.Row = 2; SimulationRadio.Layout.Column = 1;
AdaptiveCheck.Layout.Row = 3; AdaptiveCheck.Layout.Column = 1;
```

### 7. Edit Parameters Panel
**Location**: MainGrid(4,1:3)
```matlab
% Panel properties
EditPanel.Layout.Row = 4;
EditPanel.Layout.Column = [1, 3];  % Spans columns 1-3

% Internal grid (2×6)
EditGrid.RowHeight = {'1x', '1x'};
EditGrid.ColumnWidth = {'100px', '80px', '100px', '80px', '100px', '80px'};

% Edit controls positions
L1EditLabel.Layout.Row = 1; L1EditLabel.Layout.Column = 1;
L1EditField.Layout.Row = 1; L1EditField.Layout.Column = 2;
I1EditLabel.Layout.Row = 1; I1EditLabel.Layout.Column = 3;
I1EditField.Layout.Row = 1; I1EditField.Layout.Column = 4;
L2EditLabel.Layout.Row = 1; L2EditLabel.Layout.Column = 5;
L2EditField.Layout.Row = 1; L2EditField.Layout.Column = 6;

I2EditLabel.Layout.Row = 2; I2EditLabel.Layout.Column = 1;
I2EditField.Layout.Row = 2; I2EditField.Layout.Column = 2;
L3EditLabel.Layout.Row = 2; L3EditLabel.Layout.Column = 3;
L3EditField.Layout.Row = 2; L3EditField.Layout.Column = 4;
RewardEditLabel.Layout.Row = 2; RewardEditLabel.Layout.Column = 5;
RewardEditField.Layout.Row = 2; RewardEditField.Layout.Column = 6;
```

### 8. Statistics Panel
**Location**: MainGrid(5,1:3)
```matlab
% Panel properties
StatsPanel.Layout.Row = 5;
StatsPanel.Layout.Column = [1, 3];  % Spans columns 1-3

% Internal grid (2×4)
StatsGrid.RowHeight = {'1x', '1x'};
StatsGrid.ColumnWidth = {'120px', '80px', '120px', '80px'};

% Statistics display positions
SuccessLabel.Layout.Row = 1; SuccessLabel.Layout.Column = 1;
SuccessValue.Layout.Row = 1; SuccessValue.Layout.Column = 2;
AvgRTLabel.Layout.Row = 1; AvgRTLabel.Layout.Column = 3;
AvgRTValue.Layout.Row = 1; AvgRTValue.Layout.Column = 4;

TotalTrialsLabel.Layout.Row = 2; TotalTrialsLabel.Layout.Column = 1;
TotalTrialsValue.Layout.Row = 2; TotalTrialsValue.Layout.Column = 2;
SessionTimeLabel.Layout.Row = 2; SessionTimeLabel.Layout.Column = 3;
SessionTimeValue.Layout.Row = 2; SessionTimeValue.Layout.Column = 4;
```

### 9. Control Panel
**Location**: MainGrid(6,1:3)
```matlab
% Panel properties
ControlPanel.Layout.Row = 6;
ControlPanel.Layout.Column = [1, 3];  % Spans columns 1-3

% Internal grid (1×5)
ControlGrid.RowHeight = {'1x'};
ControlGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};

% Control buttons
StartButton.Layout.Row = 1; StartButton.Layout.Column = 1;
PauseButton.Layout.Row = 1; PauseButton.Layout.Column = 2;
ResetButton.Layout.Row = 1; ResetButton.Layout.Column = 3;
SaveButton.Layout.Row = 1; SaveButton.Layout.Column = 4;
ExportButton.Layout.Row = 1; ExportButton.Layout.Column = 5;

% Button properties
ButtonHeight = 35;  % pixels
ButtonColors = {
    'Start': [0.0, 0.7, 0.0],
    'Pause': [1.0, 0.6, 0.0],
    'Reset': [0.7, 0.0, 0.0],
    'Save': [0.0, 0.0, 0.7],
    'Export': [0.5, 0.0, 0.5]
};
```

## Common Adjustment Operations

### Resizing Panels
```matlab
% Adjust main grid row heights
MainGrid.RowHeight = {
    '80px',   % Row 1: Fixed height for info panels
    '60px',   % Row 2: Fixed height for result strip
    '100px',  % Row 3: Fixed height for parameters
    '80px',   % Row 4: Fixed height for edit controls
    '80px',   % Row 5: Fixed height for statistics
    '50px'    % Row 6: Fixed height for controls
};

% Adjust main grid column widths
MainGrid.ColumnWidth = {
    '300px',  % Column 1: Fixed width
    '1x',     % Column 2: Flexible width
    '200px'   % Column 3: Fixed width
};
```

### Changing Component Spacing
```matlab
% Adjust internal grid spacing
SessionGrid.Padding = [5, 5, 5, 5];  % [top, right, bottom, left]
SessionGrid.RowSpacing = 5;          % Vertical spacing between rows
SessionGrid.ColumnSpacing = 10;      % Horizontal spacing between columns
```

### Modifying Font Sizes
```matlab
% Label font sizes
LabelFontSize = 12;
ValueFontSize = 11;
TitleFontSize = 14;

% Apply to components
SubjectLabel.FontSize = LabelFontSize;
SubjectField.FontSize = ValueFontSize;
SessionPanel.Title.FontSize = TitleFontSize;
```

### Adjusting Colors
```matlab
% Panel background colors
PanelBackgroundColor = [0.95, 0.95, 0.95];
SessionPanel.BackgroundColor = PanelBackgroundColor;

% Text colors
LabelTextColor = [0.2, 0.2, 0.2];
ValueTextColor = [0.0, 0.0, 0.0];
SubjectLabel.FontColor = LabelTextColor;
SubjectField.FontColor = ValueTextColor;
```

## Result Display Customization

### Result Strip Configuration
```matlab
% Result strip properties
ResultStrip.MaxDisplayResults = 50;
ResultStrip.ResultWidth = 8;         % Width of each result indicator
ResultStrip.ResultHeight = 20;       % Height of result indicators
ResultStrip.ResultSpacing = 2;       % Spacing between indicators

% Result colors (RGB values)
ResultStrip.Colors = containers.Map(...
    {0, 1, 2, 3, 4}, ...
    {[0.0, 0.8, 0.0], [1.0, 0.5, 0.0], [1.0, 0.0, 0.0], ...
     [0.5, 0.0, 0.5], [0.8, 0.8, 0.0]}
);

% Animation settings
ResultStrip.AnimationDuration = 0.3;  % seconds
ResultStrip.FadeInEffect = true;
```

### LED Indicator Customization
```matlab
% LED appearance
LED_Diameter = 40;                   % pixels
LED_BorderWidth = 2;                 % pixels
LED_BorderColor = [0.3, 0.3, 0.3];

% LED states and colors
LED_States = {
    'off': [0.8, 0.8, 0.8],         % Gray
    'on': [1.0, 0.0, 0.0],          % Red
    'active': [0.0, 1.0, 0.0],      % Green
    'warning': [1.0, 1.0, 0.0]      % Yellow
};

% LED animation
LED_BlinkRate = 2;                   % Hz
LED_FadeTime = 0.2;                  % seconds
```

## Debugging Tips

### Layout Inspection
```matlab
% Check component positions
fprintf('Panel position: [%.1f, %.1f, %.1f, %.1f]\n', ...
        SessionPanel.Position);

% Verify grid settings
fprintf('Grid rows: %d, columns: %d\n', ...
        MainGrid.RowHeight.length, MainGrid.ColumnWidth.length);

% List all child components
children = MainGrid.Children;
for i = 1:length(children)
    fprintf('Child %d: %s\n', i, class(children(i)));
end
```

### Common Layout Issues
1. **Components not visible**: Check Layout.Row and Layout.Column properties
2. **Overlapping elements**: Verify grid dimensions and component positions
3. **Incorrect sizing**: Check RowHeight and ColumnWidth settings
4. **Alignment problems**: Verify Padding and Spacing properties

### Performance Optimization
```matlab
% Disable automatic resizing during batch updates
MainGrid.AutoResizeChildren = 'off';

% Batch property updates
set([Label1, Label2, Label3], 'FontSize', 12);

% Re-enable automatic resizing
MainGrid.AutoResizeChildren = 'on';
```

## Important Considerations

### Responsive Design
- Use flexible sizing ('1x') for main content areas
- Use fixed sizing ('XXXpx') for control elements
- Consider minimum window size requirements
- Test layout at different screen resolutions

### Accessibility
- Maintain adequate contrast ratios
- Use appropriate font sizes (minimum 10pt)
- Provide keyboard navigation support
- Include tooltips for complex controls

### Performance
- Minimize frequent layout updates
- Use batch property changes when possible
- Avoid excessive nesting of grid layouts
- Consider component pooling for dynamic elements

### Cross-platform Compatibility
- Test on different operating systems
- Verify font availability across platforms
- Check color rendering consistency
- Validate layout behavior with different DPI settings

---

**Note**: This guide covers the standard layout configuration. For advanced customizations or specific requirements, refer to the MATLAB App Designer documentation or contact the development team.