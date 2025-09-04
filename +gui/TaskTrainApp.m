classdef TaskTrainApp < matlab.apps.AppBase
    % Three-key sequence mouse training task main interface
    % MATLAB App Designer application
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        MainGrid                   matlab.ui.container.GridLayout
        
        % Session information panel
        SessionPanel               matlab.ui.container.Panel
        SessionGrid                matlab.ui.container.GridLayout
        SubjectLabel               matlab.ui.control.Label
        SubjectIDField             matlab.ui.control.EditField
        SessionLabel               matlab.ui.control.Label
        SessionLabelField          matlab.ui.control.EditField
        ModeLabel                  matlab.ui.control.Label
        ModeDropDown               matlab.ui.control.DropDown
        
        % Status display panel
        StatusPanel                matlab.ui.container.Panel
        StatusGrid                 matlab.ui.container.GridLayout
        CurrentStateLabel          matlab.ui.control.Label
        CountdownLabel             matlab.ui.control.Label
        TrialProgressLabel         matlab.ui.control.Label
        
        % LED indicator panel
        LEDPanel                   matlab.ui.container.Panel
        LEDGrid                    matlab.ui.container.GridLayout
        LED1Lamp                   matlab.ui.control.Lamp
        LED2Lamp                   matlab.ui.control.Lamp
        LED3Lamp                   matlab.ui.control.Lamp
        RewardLamp                 matlab.ui.control.Lamp
        LED1Label                  matlab.ui.control.Label
        LED2Label                  matlab.ui.control.Label
        LED3Label                  matlab.ui.control.Label
        RewardLabel                matlab.ui.control.Label
        
        % Results strip panel
        ResultsPanel               matlab.ui.container.Panel
        ResultsGrid                matlab.ui.container.GridLayout
        ResultsAxes                matlab.ui.control.UIAxes
        
        % Statistics panel
        StatsPanel                 matlab.ui.container.Panel
        StatsGrid                  matlab.ui.container.GridLayout
        StatsTable                 matlab.ui.control.Table
        
        % Parameters display panel
        ParamsPanel                matlab.ui.container.Panel
        ParamsGrid                 matlab.ui.container.GridLayout
        ParamsTable                matlab.ui.control.Table
        
        % Parameter editing components
        EditParamsPanel            matlab.ui.container.Panel
        EditParamsGrid             matlab.ui.container.GridLayout
        WaitL1Field                matlab.ui.control.NumericEditField
        WaitL2Field                matlab.ui.control.NumericEditField
        WaitL3Field                matlab.ui.control.NumericEditField
        I1Field                    matlab.ui.control.NumericEditField
        I2Field                    matlab.ui.control.NumericEditField
        ReleaseWindowField         matlab.ui.control.NumericEditField
        ITICorrectFixedField       matlab.ui.control.NumericEditField
        ITICorrectRandField        matlab.ui.control.NumericEditField
        ITIErrorFixedField         matlab.ui.control.NumericEditField
        ITIErrorRandField          matlab.ui.control.NumericEditField
        ApplyParamsButton          matlab.ui.control.Button
        SaveParamsButton           matlab.ui.control.Button
        LoadParamsButton           matlab.ui.control.Button
        
        % Shaping mode options
        ShapingOptionsPanel        matlab.ui.container.Panel
        ShapingOptionsGrid         matlab.ui.container.GridLayout
        ShapingLEDDropDown         matlab.ui.control.DropDown
        ShapingRandomCheckBox      matlab.ui.control.CheckBox
        
        % Sequence mode options
        SequenceOptionsPanel       matlab.ui.container.Panel
        SequenceOptionsGrid        matlab.ui.container.GridLayout
        SequenceOrderField         matlab.ui.control.EditField
        SequenceRandomCheckBox     matlab.ui.control.CheckBox
        
        % Control button panel
        ControlPanel               matlab.ui.container.Panel
        ControlGrid                matlab.ui.container.GridLayout
        StartPauseButton           matlab.ui.control.Button
        ResetButton                matlab.ui.control.Button
        ConfigButton               matlab.ui.control.Button
        DataButton                 matlab.ui.control.Button
        HardwareButton             matlab.ui.control.Button
        
        % Menus
        MainMenu                   matlab.ui.container.Menu
        FileMenu                   matlab.ui.container.Menu
        LoadConfigMenu             matlab.ui.container.Menu
        SaveConfigMenu             matlab.ui.container.Menu
        ExportDataMenu             matlab.ui.container.Menu
        ExitMenu                   matlab.ui.container.Menu
        ToolsMenu                  matlab.ui.container.Menu
        HardwareTestMenu           matlab.ui.container.Menu
        SimModeMenu                matlab.ui.container.Menu
        HelpMenu                   matlab.ui.container.Menu
        AboutMenu                  matlab.ui.container.Menu
        % Small square display: squares per row & cell padding (0~0.45)
        resultGridCols = 20;      % How many squares per row; increase for denser display
        resultGridPad  = 0.12;    % Cell padding (proportion of cell width), controls spacing between squares
    end
    
    properties (Access = private)
        % Core components
        config                     % Configuration object
        stateMachine              % State machine
        ioBackend                 % IO backend
        logger                    % Data logger
        adaptive                  % Adaptive controller
        
        % UI update timer
        updateTimer               % UI update timer
        
        % State variables
        isRunning = false         % Whether currently running
        isPaused = false          % Whether paused
        sessionStartTime = 0      % Session start time
        
        % Result display
        resultColors = [0 1 0; 1 0 0; 1 0.5 0; 1 0 1; 0 0 1]  % Result colors
        resultHistory = []        % Result history
        maxResultsDisplay = inf    % Maximum number of results to display
        
        % Event listeners
        stateChangeListener       % State change listener
        trialCompleteListener     % Trial completion listener
        parameterAdjustListener   % Parameter adjustment listener
        resultSquarePx = 10;   % Target square side length (pixels), use 8 or 6 for smaller
        resultGapPx    = 2;    % Gap between squares (pixels)
        
        % Random mode settings
        shapingRandomMode = false;   % Whether shaping mode uses random LEDs
        sequenceRandomMode = false;  % Whether sequence mode uses random order
        customSequenceOrder = [1, 2, 3];  % Custom sequence order for sequence mode
    end
    
    methods (Access = private)
        
        function createComponents(app)
            % Create UI components
            
            % Create main window
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 800];
            app.UIFigure.Name = 'Three-Key Sequence Mouse Training Task';
            app.UIFigure.Icon = '';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.KeyPressFcn = createCallbackFcn(app, @UIFigureKeyPress, true);
            
            % Create main grid layout
            app.MainGrid = uigridlayout(app.UIFigure);
            app.MainGrid.ColumnWidth = {'2x', '1x', '1x', '1x'};
            app.MainGrid.RowHeight = {60, 80, '1x', '1x', '1x', '1x', 80};
            app.MainGrid.Padding = [10 10 10 10];
            app.MainGrid.RowSpacing = 10;
            app.MainGrid.ColumnSpacing = 10;
            
            % Create menus
            app.createMenus();
            
            % Create panels
            app.createSessionPanel();
            app.createStatusPanel();
            app.StatusPanel.Layout.Row    = 1;
            app.StatusPanel.Layout.Column = [2 3];
            app.createLEDPanel();
            D = 36;                        % LED circle size
            
            % Make cells nearly square, Lamp will be D pixel circle
            app.LEDGrid.Padding       = [4 6 4 6];   % Panel padding, adjustable
            app.LEDGrid.RowSpacing    = 2;
            app.LEDGrid.ColumnSpacing = 8;
            
            % Row 1 for lamps, row 2 for labels
            app.LEDGrid.RowHeight     = {D, 16};     % 16 for label row; increase if needed
            app.LEDGrid.ColumnWidth   = {D, D, D, D};
            app.LEDPanel.Layout.Row    = 1;
            app.LEDPanel.Layout.Column = 4;
            app.createResultsPanel();
            app.createStatsPanel();
            app.createParamsPanel();
            app.createEditParamsPanel();
            app.createModeOptionsPanel();
            app.createControlPanel();
            
            % Show window
            app.UIFigure.Visible = 'on';
        end
        
        function createMenus(app)
            % Create menu bar
            
            % File menu
            app.FileMenu = uimenu(app.UIFigure, 'Text', 'File');
            app.LoadConfigMenu = uimenu(app.FileMenu, 'Text', 'Load Config', ...
                'MenuSelectedFcn', createCallbackFcn(app, @LoadConfigMenuSelected, true));
            app.SaveConfigMenu = uimenu(app.FileMenu, 'Text', 'Save Config', ...
                'MenuSelectedFcn', createCallbackFcn(app, @SaveConfigMenuSelected, true));
            app.ExportDataMenu = uimenu(app.FileMenu, 'Text', 'Export Data', ...
                'MenuSelectedFcn', createCallbackFcn(app, @ExportDataMenuSelected, true));
            app.ExitMenu = uimenu(app.FileMenu, 'Text', 'Exit', ...
                'MenuSelectedFcn', createCallbackFcn(app, @ExitMenuSelected, true));
            
            % Tools menu
            app.ToolsMenu = uimenu(app.UIFigure, 'Text', 'Tools');
            app.HardwareTestMenu = uimenu(app.ToolsMenu, 'Text', 'Hardware Test', ...
                'MenuSelectedFcn', createCallbackFcn(app, @HardwareTestMenuSelected, true));
            app.SimModeMenu = uimenu(app.ToolsMenu, 'Text', 'Simulation Mode', ...
                'MenuSelectedFcn', createCallbackFcn(app, @SimModeMenuSelected, true));
            
            % Help menu
            app.HelpMenu = uimenu(app.UIFigure, 'Text', 'Help');
            app.AboutMenu = uimenu(app.HelpMenu, 'Text', 'About', ...
                'MenuSelectedFcn', createCallbackFcn(app, @AboutMenuSelected, true));
        end
        
        function createSessionPanel(app)
            % Create session information panel
            app.SessionPanel = uipanel(app.MainGrid);
            app.SessionPanel.Title = 'Session Information';
            app.SessionPanel.Layout.Row = 1;
            app.SessionPanel.Layout.Column = [1];
            
            app.SessionGrid = uigridlayout(app.SessionPanel);
            app.SessionGrid.ColumnWidth = {60, 40, 50, 30, 40, 100};
            app.SessionGrid.RowHeight = {'1x'};
            
            % Subject ID
            app.SubjectLabel = uilabel(app.SessionGrid);
            app.SubjectLabel.Text = 'Subject ID:';
            app.SubjectLabel.Layout.Row = 1;
            app.SubjectLabel.Layout.Column = 1;
            
            app.SubjectIDField = uieditfield(app.SessionGrid, 'text');
            app.SubjectIDField.Value = 'M001';
            app.SubjectIDField.Layout.Row = 1;
            app.SubjectIDField.Layout.Column = 2;
            
            % Session label
            app.SessionLabel = uilabel(app.SessionGrid);
            app.SessionLabel.Text = 'Session:';
            app.SessionLabel.Layout.Row = 1;
            app.SessionLabel.Layout.Column = 3;
            
            app.SessionLabelField = uieditfield(app.SessionGrid, 'text');
            app.SessionLabelField.Layout.Row = 1;
            app.SessionLabelField.Layout.Column = 4;
            
            % Mode selection
            app.ModeLabel = uilabel(app.SessionGrid);
            app.ModeLabel.Text = 'Mode:';
            app.ModeLabel.Layout.Row = 1;
            app.ModeLabel.Layout.Column = 5;
            
            app.ModeDropDown = uidropdown(app.SessionGrid);
            app.ModeDropDown.Items = {'Sequence-3', 'Shaping-1'};
            app.ModeDropDown.Value = 'Sequence-3';
            app.ModeDropDown.Layout.Row = 1;
            app.ModeDropDown.Layout.Column = 6;
        end
        
        function createStatusPanel(app)
            % Create current status panel
            app.StatusPanel = uipanel(app.MainGrid);
            app.StatusPanel.Title = 'Current Status';
            
            app.StatusGrid = uigridlayout(app.StatusPanel);
            app.StatusGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.StatusGrid.RowHeight = {'1x'};
            
            % Current status
            app.CurrentStateLabel = uilabel(app.StatusGrid);
            app.CurrentStateLabel.Text = 'Status: ITI';
            app.CurrentStateLabel.FontSize = 16;
            app.CurrentStateLabel.FontWeight = 'bold';
            app.CurrentStateLabel.HorizontalAlignment = 'center';
            app.CurrentStateLabel.Layout.Row = 1;
            app.CurrentStateLabel.Layout.Column = 1;
            
            % Countdown
            app.CountdownLabel = uilabel(app.StatusGrid);
            app.CountdownLabel.Text = 'Countdown: --';
            app.CountdownLabel.FontSize = 16;
            app.CountdownLabel.FontWeight = 'bold';
            app.CountdownLabel.HorizontalAlignment = 'center';
            app.CountdownLabel.Layout.Row = 1;
            app.CountdownLabel.Layout.Column = 2;
            
            % Trial progress
            app.TrialProgressLabel = uilabel(app.StatusGrid);
            app.TrialProgressLabel.Text = 'Trial: 0/500';
            app.TrialProgressLabel.FontSize = 16;
            app.TrialProgressLabel.FontWeight = 'bold';
            app.TrialProgressLabel.HorizontalAlignment = 'center';
            app.TrialProgressLabel.Layout.Row = 1;
            app.TrialProgressLabel.Layout.Column = 3;
        end
        
        function createLEDPanel(app)
            % Create LED indicator panel
            app.LEDPanel = uipanel(app.MainGrid);
            app.LEDPanel.Title = 'LED Indicators';
            
            app.LEDGrid = uigridlayout(app.LEDPanel);
            app.LEDGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.LEDGrid.RowHeight = {60, 30};
            
            % LED lamps
            app.LED1Lamp = uilamp(app.LEDGrid);
            app.LED1Lamp.Color = [0.5 0.5 0.5];
            app.LED1Lamp.Layout.Row = 1;
            app.LED1Lamp.Layout.Column = 1;
            
            app.LED2Lamp = uilamp(app.LEDGrid);
            app.LED2Lamp.Color = [0.5 0.5 0.5];
            app.LED2Lamp.Layout.Row = 1;
            app.LED2Lamp.Layout.Column = 2;
            
            app.LED3Lamp = uilamp(app.LEDGrid);
            app.LED3Lamp.Color = [0.5 0.5 0.5];
            app.LED3Lamp.Layout.Row = 1;
            app.LED3Lamp.Layout.Column = 3;
            
            app.RewardLamp = uilamp(app.LEDGrid);
            app.RewardLamp.Color = [0.5 0.5 0.5];
            app.RewardLamp.Layout.Row = 1;
            app.RewardLamp.Layout.Column = 4;
            
            % LED labels
            app.LED1Label = uilabel(app.LEDGrid);
            app.LED1Label.Text = 'LED1';
            app.LED1Label.HorizontalAlignment = 'center';
            app.LED1Label.Layout.Row = 2;
            app.LED1Label.Layout.Column = 1;
            
            app.LED2Label = uilabel(app.LEDGrid);
            app.LED2Label.Text = 'LED2';
            app.LED2Label.HorizontalAlignment = 'center';
            app.LED2Label.Layout.Row = 2;
            app.LED2Label.Layout.Column = 2;
            
            app.LED3Label = uilabel(app.LEDGrid);
            app.LED3Label.Text = 'LED3';
            app.LED3Label.HorizontalAlignment = 'center';
            app.LED3Label.Layout.Row = 2;
            app.LED3Label.Layout.Column = 3;
            
            app.RewardLabel = uilabel(app.LEDGrid);
            app.RewardLabel.Text = 'Reward';
            app.RewardLabel.HorizontalAlignment = 'center';
            app.RewardLabel.Layout.Row = 2;
            app.RewardLabel.Layout.Column = 4;
        end
        
        function createResultsPanel(app)
            % Create recent trial results panel
            app.ResultsPanel = uipanel(app.MainGrid);
            app.ResultsPanel.Title = 'Recent Trial Results';
            app.ResultsPanel.Layout.Row = [2 3];
            app.ResultsPanel.Layout.Column = [1 4];
            
            % Results display grid
            %app.ResultsGrid = uigridlayout(app.ResultsPanel);
            %app.ResultsGrid.ColumnWidth = repmat({'1x'}, 1, app.resultGridCols);
            %app.ResultsGrid.RowHeight = repmat({'1x'}, 1, ceil(app.maxResultsDisplay/app.resultGridCols));
            app.ResultsGrid = uigridlayout(app.ResultsPanel,[1 1]);
            app.ResultsGrid.ColumnWidth = {'1x'};
            app.ResultsGrid.RowHeight   = {'1x'};
            % app.ResultsGrid.Padding = [5 5 5 5];
            % app.ResultsGrid.ColumnSpacing = 2;
            % app.ResultsGrid.RowSpacing = 2;
            
            app.ResultsAxes = uiaxes(app.ResultsGrid);
            app.ResultsAxes.Layout.Row = 1;
            app.ResultsAxes.Layout.Column = 1;
            app.ResultsAxes.XTick = []; app.ResultsAxes.YTick = [];
            app.ResultsAxes.Box = 'on';
            title(app.ResultsAxes,'试次结果（小方块，自动换行）');
            app.ResultsGrid.Padding = [5 5 5 5];
            app.ResultsGrid.ColumnSpacing = 2;
            app.ResultsGrid.RowSpacing = 2;
            
            % Initialize result display squares
            % app.ResultSquares = cell(ceil(app.maxResultsDisplay/app.resultGridCols), app.resultGridCols);
            % for i = 1:ceil(app.maxResultsDisplay/app.resultGridCols)
            %     for j = 1:app.resultGridCols
            %         app.ResultSquares{i,j} = uipanel(app.ResultsGrid);
            %         app.ResultSquares{i,j}.BackgroundColor = [0.9 0.9 0.9]; % Gray
            %         app.ResultSquares{i,j}.BorderType = 'line';
            %         app.ResultSquares{i,j}.Layout.Row = i;
            %         app.ResultSquares{i,j}.Layout.Column = j;
            %     end
            % end
        end
        
        function createStatsPanel(app)
            % Create statistics panel
            app.StatsPanel = uipanel(app.MainGrid);
            app.StatsPanel.Title = 'Statistics';
            app.StatsPanel.Layout.Row = [4 6];
            app.StatsPanel.Layout.Column = 3;
            
            app.StatsGrid = uigridlayout(app.StatsPanel);
            app.StatsGrid.ColumnWidth = {'1x'};
            app.StatsGrid.RowHeight = {'1x'};
            
            app.StatsTable = uitable(app.StatsGrid);
            app.StatsTable.Layout.Row = 1;
            app.StatsTable.Layout.Column = 1;
            app.StatsTable.ColumnName = {'Item', 'Value'};
            app.StatsTable.ColumnEditable = [false false];
            app.StatsTable.Data = {
                'Total Trials', '0';
                'Correct Trials', '0 (0%)';
                'Error Trials', '0';
                'No Press', '0';
                'Wrong Button', '0';
                'Hold Too Long', '0';
                'Premature Press', '0';
                'ITI Error', '0'
            };
        end
        
        function createParamsPanel(app)
            % Create current parameters panel
            app.ParamsPanel = uipanel(app.MainGrid);
            app.ParamsPanel.Title = 'Current Parameters';
            app.ParamsPanel.Layout.Row = [4 6];
            app.ParamsPanel.Layout.Column = 4;
            
            app.ParamsGrid = uigridlayout(app.ParamsPanel);
            app.ParamsGrid.ColumnWidth = {'1x'};
            app.ParamsGrid.RowHeight = {'1x'};
            
            app.ParamsTable = uitable(app.ParamsGrid);
            app.ParamsTable.Layout.Row = 1;
            app.ParamsTable.Layout.Column = 1;
            app.ParamsTable.ColumnName = {'Parameter', 'Value'};
            app.ParamsTable.ColumnEditable = [false false];
            app.ParamsTable.Data = {
                'L1 Wait', '3.0s';
                'L2 Wait', '3.0s';
                'L3 Wait', '3.0s';
                'I1 Interval', '0.5s';
                'I2 Interval', '0.5s';
                'Release Window', '1.0s';
                'ITI Correct', '1.0±1.0s';
                'ITI Error', '2.0±1.0s'
            };
        end
        
        function createEditParamsPanel(app)
            % Create editable parameters panel
            app.EditParamsPanel = uipanel(app.MainGrid);
            app.EditParamsPanel.Title = 'Edit Parameters';
            app.EditParamsPanel.Layout.Row = [4 6];
            app.EditParamsPanel.Layout.Column = 1;
            
            app.EditParamsGrid = uigridlayout(app.EditParamsPanel);
            app.EditParamsGrid.ColumnWidth = {120, 80, 120, 80};
            app.EditParamsGrid.RowHeight = repmat({25}, 1, 7);
            app.EditParamsGrid.Padding = [5 5 5 5];
            app.EditParamsGrid.RowSpacing = 3;
            app.EditParamsGrid.ColumnSpacing = 5;
            
            % L1 Wait Time
            l1Label = uilabel(app.EditParamsGrid);
            l1Label.Text = 'L1 Wait (s):';
            l1Label.Layout.Row = 1;
            l1Label.Layout.Column = 1;
            
            app.WaitL1Field = uieditfield(app.EditParamsGrid, 'numeric');
            app.WaitL1Field.Value = 3.0;
            app.WaitL1Field.Limits = [0.1 10];
            app.WaitL1Field.Layout.Row = 1;
            app.WaitL1Field.Layout.Column = 2;
            
            % L2 Wait Time
            l2Label = uilabel(app.EditParamsGrid);
            l2Label.Text = 'L2 Wait (s):';
            l2Label.Layout.Row = 1;
            l2Label.Layout.Column = 3;
            
            app.WaitL2Field = uieditfield(app.EditParamsGrid, 'numeric');
            app.WaitL2Field.Value = 3.0;
            app.WaitL2Field.Limits = [0.1 10];
            app.WaitL2Field.Layout.Row = 1;
            app.WaitL2Field.Layout.Column = 4;
            
            % L3 Wait Time
            l3Label = uilabel(app.EditParamsGrid);
            l3Label.Text = 'L3 Wait (s):';
            l3Label.Layout.Row = 2;
            l3Label.Layout.Column = 1;
            
            app.WaitL3Field = uieditfield(app.EditParamsGrid, 'numeric');
            app.WaitL3Field.Value = 3.0;
            app.WaitL3Field.Limits = [0.1 10];
            app.WaitL3Field.Layout.Row = 2;
            app.WaitL3Field.Layout.Column = 2;
            
            % I1 Interval
            i1Label = uilabel(app.EditParamsGrid);
            i1Label.Text = 'I1 interval (s):';
            i1Label.Layout.Row = 2;
            i1Label.Layout.Column = 3;
            
            app.I1Field = uieditfield(app.EditParamsGrid, 'numeric');
            app.I1Field.Value = 0.5;
            app.I1Field.Limits = [0.1 5];
            app.I1Field.Layout.Row = 2;
            app.I1Field.Layout.Column = 4;
            
            % I2 Interval
            i2Label = uilabel(app.EditParamsGrid);
            i2Label.Text = 'I2 interval (s):';
            i2Label.Layout.Row = 3;
            i2Label.Layout.Column = 1;
            
            app.I2Field = uieditfield(app.EditParamsGrid, 'numeric');
            app.I2Field.Value = 0.5;
            app.I2Field.Limits = [0.1 5];
            app.I2Field.Layout.Row = 3;
            app.I2Field.Layout.Column = 2;
            
            % Release Window
            rwLabel = uilabel(app.EditParamsGrid);
            rwLabel.Text = 'Release Window (s):';
            rwLabel.Layout.Row = 3;
            rwLabel.Layout.Column = 3;
            
            app.ReleaseWindowField = uieditfield(app.EditParamsGrid, 'numeric');
            app.ReleaseWindowField.Value = 1.0;
            app.ReleaseWindowField.Limits = [0.1 5];
            app.ReleaseWindowField.Layout.Row = 3;
            app.ReleaseWindowField.Layout.Column = 4;
            
            % ITI Correct Fixed
            itiCFLabel = uilabel(app.EditParamsGrid);
            itiCFLabel.Text = 'ITI Correct Fixed (s):';
            itiCFLabel.Layout.Row = 4;
            itiCFLabel.Layout.Column = 1;
            
            app.ITICorrectFixedField = uieditfield(app.EditParamsGrid, 'numeric');
            app.ITICorrectFixedField.Value = 1.0;
            app.ITICorrectFixedField.Limits = [0.1 10];
            app.ITICorrectFixedField.Layout.Row = 4;
            app.ITICorrectFixedField.Layout.Column = 2;
            
            % ITI Correct Random
            itiCRLabel = uilabel(app.EditParamsGrid);
            itiCRLabel.Text = 'ITI Correct Rand (s):';
            itiCRLabel.Layout.Row = 4;
            itiCRLabel.Layout.Column = 3;
            
            app.ITICorrectRandField = uieditfield(app.EditParamsGrid, 'numeric');
            app.ITICorrectRandField.Value = 1.0;
            app.ITICorrectRandField.Limits = [0 5];
            app.ITICorrectRandField.Layout.Row = 4;
            app.ITICorrectRandField.Layout.Column = 4;
            
            % ITI Error Fixed
            itiEFLabel = uilabel(app.EditParamsGrid);
            itiEFLabel.Text = 'ITI Error Fixed (s):';
            itiEFLabel.Layout.Row = 5;
            itiEFLabel.Layout.Column = 1;
            
            app.ITIErrorFixedField = uieditfield(app.EditParamsGrid, 'numeric');
            app.ITIErrorFixedField.Value = 2.0;
            app.ITIErrorFixedField.Limits = [0.1 10];
            app.ITIErrorFixedField.Layout.Row = 5;
            app.ITIErrorFixedField.Layout.Column = 2;
            
            % ITI Error Random
            itiERLabel = uilabel(app.EditParamsGrid);
            itiERLabel.Text = 'ITI Error Rand (s):';
            itiERLabel.Layout.Row = 5;
            itiERLabel.Layout.Column = 3;
            
            app.ITIErrorRandField = uieditfield(app.EditParamsGrid, 'numeric');
            app.ITIErrorRandField.Value = 1.0;
            app.ITIErrorRandField.Limits = [0 5];
            app.ITIErrorRandField.Layout.Row = 5;
            app.ITIErrorRandField.Layout.Column = 4;
            
            % Apply Button
            app.ApplyParamsButton = uibutton(app.EditParamsGrid, 'push');
            app.ApplyParamsButton.Text = 'Apply';
            app.ApplyParamsButton.FontWeight = 'bold';
            app.ApplyParamsButton.BackgroundColor = [0 0.8 0.4];
            app.ApplyParamsButton.FontColor = [1 1 1];
            app.ApplyParamsButton.Layout.Row = 6;
            app.ApplyParamsButton.Layout.Column = [1 2];
            app.ApplyParamsButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyParamsButtonPushed, true);
            
            % Save Button
            app.SaveParamsButton = uibutton(app.EditParamsGrid, 'push');
            app.SaveParamsButton.Text = 'Save';
            app.SaveParamsButton.Layout.Row = 6;
            app.SaveParamsButton.Layout.Column = 3;
            app.SaveParamsButton.ButtonPushedFcn = createCallbackFcn(app, @SaveParamsButtonPushed, true);
            
            % Load Button
            app.LoadParamsButton = uibutton(app.EditParamsGrid, 'push');
            app.LoadParamsButton.Text = 'Load';
            app.LoadParamsButton.Layout.Row = 6;
            app.LoadParamsButton.Layout.Column = 4;
            app.LoadParamsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadParamsButtonPushed, true);
        end
        
        function createModeOptionsPanel(app)
            % Create mode-specific options panel
            app.ShapingOptionsPanel = uipanel(app.MainGrid);
            app.ShapingOptionsPanel.Title = 'Shaping Mode Options';
            app.ShapingOptionsPanel.Layout.Row = 6;
            app.ShapingOptionsPanel.Layout.Column = 2;
            
            app.ShapingOptionsGrid = uigridlayout(app.ShapingOptionsPanel);
            app.ShapingOptionsGrid.ColumnWidth = {'1x', '1x'};
            app.ShapingOptionsGrid.RowHeight = {30, 30};
            app.ShapingOptionsGrid.Padding = [5 5 5 5];
            
            % Shaping LED Selection
            shapingLEDLabel = uilabel(app.ShapingOptionsGrid);
            shapingLEDLabel.Text = 'Target LED:';
            shapingLEDLabel.Layout.Row = 1;
            shapingLEDLabel.Layout.Column = 1;
            
            app.ShapingLEDDropDown = uidropdown(app.ShapingOptionsGrid);
            app.ShapingLEDDropDown.Items = {'LED1', 'LED2', 'LED3'};
            app.ShapingLEDDropDown.Value = 'LED1';
            app.ShapingLEDDropDown.Layout.Row = 1;
            app.ShapingLEDDropDown.Layout.Column = 2;
            
            % Random Mode for Shaping
            shapingRandomLabel = uilabel(app.ShapingOptionsGrid);
            shapingRandomLabel.Text = 'Random Mode:';
            shapingRandomLabel.Layout.Row = 2;
            shapingRandomLabel.Layout.Column = 1;
            
            app.ShapingRandomCheckBox = uicheckbox(app.ShapingOptionsGrid);
            app.ShapingRandomCheckBox.Text = 'Enable';
            app.ShapingRandomCheckBox.Layout.Row = 2;
            app.ShapingRandomCheckBox.Layout.Column = 2;
            
            % Sequence Mode Options
            app.SequenceOptionsPanel = uipanel(app.MainGrid);
            app.SequenceOptionsPanel.Title = 'Sequence Mode Options';
            app.SequenceOptionsPanel.Layout.Row = [4 5];
            app.SequenceOptionsPanel.Layout.Column = 2;
            
            app.SequenceOptionsGrid = uigridlayout(app.SequenceOptionsPanel);
            app.SequenceOptionsGrid.ColumnWidth = {'1x'};
            app.SequenceOptionsGrid.RowHeight = {25, 30, 25, 30};
            app.SequenceOptionsGrid.Padding = [5 5 5 5];
            
            % Sequence Order
            seqOrderLabel = uilabel(app.SequenceOptionsGrid);
            seqOrderLabel.Text = 'Button Order:';
            seqOrderLabel.Layout.Row = 1;
            seqOrderLabel.Layout.Column = 1;
            
            app.SequenceOrderField = uieditfield(app.SequenceOptionsGrid, 'text');
            app.SequenceOrderField.Value = '1,2,3';
            app.SequenceOrderField.Layout.Row = 2;
            app.SequenceOrderField.Layout.Column = 1;
            
            % Random Mode for Sequence
            seqRandomLabel = uilabel(app.SequenceOptionsGrid);
            seqRandomLabel.Text = 'Random Order:';
            seqRandomLabel.Layout.Row = 3;
            seqRandomLabel.Layout.Column = 1;
            
            app.SequenceRandomCheckBox = uicheckbox(app.SequenceOptionsGrid);
            app.SequenceRandomCheckBox.Text = 'Enable Random';
            app.SequenceRandomCheckBox.Layout.Row = 4;
            app.SequenceRandomCheckBox.Layout.Column = 1;
        end
        
        function createControlPanel(app)
            % Create control panel
            app.ControlPanel = uipanel(app.MainGrid);
            app.ControlPanel.Title = 'Control';
            app.ControlPanel.Layout.Row = 7;
            app.ControlPanel.Layout.Column = [1 4];
            
            app.ControlGrid = uigridlayout(app.ControlPanel);
            app.ControlGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.ControlGrid.RowHeight = {'1x'};
            
            % Start/Pause button
            app.StartPauseButton = uibutton(app.ControlGrid, 'push');
            app.StartPauseButton.Text = 'Start';
            app.StartPauseButton.FontSize = 14;
            app.StartPauseButton.FontWeight = 'bold';
            app.StartPauseButton.BackgroundColor = [0 0.8 0];
            app.StartPauseButton.FontColor = [1 1 1];
            app.StartPauseButton.Layout.Row = 1;
            app.StartPauseButton.Layout.Column = 1;
            app.StartPauseButton.ButtonPushedFcn = createCallbackFcn(app, @StartPauseButtonPushed, true);
            
            % Reset button
            app.ResetButton = uibutton(app.ControlGrid, 'push');
            app.ResetButton.Text = 'Reset';
            app.ResetButton.FontSize = 14;
            app.ResetButton.Layout.Row = 1;
            app.ResetButton.Layout.Column = 2;
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            
            % Config button
            app.ConfigButton = uibutton(app.ControlGrid, 'push');
            app.ConfigButton.Text = 'Config';
            app.ConfigButton.FontSize = 14;
            app.ConfigButton.Layout.Row = 1;
            app.ConfigButton.Layout.Column = 3;
            app.ConfigButton.ButtonPushedFcn = createCallbackFcn(app, @ConfigButtonPushed, true);
            
            % Data button
            app.DataButton = uibutton(app.ControlGrid, 'push');
            app.DataButton.Text = 'Data';
            app.DataButton.FontSize = 14;
            app.DataButton.Layout.Row = 1;
            app.DataButton.Layout.Column = 4;
            app.DataButton.ButtonPushedFcn = createCallbackFcn(app, @DataButtonPushed, true);
            
            % Hardware button
            app.HardwareButton = uibutton(app.ControlGrid, 'push');
            app.HardwareButton.Text = 'Hardware';
            app.HardwareButton.FontSize = 14;
            app.HardwareButton.Layout.Row = 1;
            app.HardwareButton.Layout.Column = 5;
            app.HardwareButton.ButtonPushedFcn = createCallbackFcn(app, @HardwareButtonPushed, true);
        end
    end
    
    % Callbacks that handle component events
    methods (Access = private)

        function startupFcn(app)
            % Execute when application starts
            app.initializeApplication();
        end
        
        function UIFigureCloseRequest(app, event)
            % Window close request
            app.cleanupApplication();
            delete(app);
        end
        
        function UIFigureKeyPress(app, event)
            % Keyboard key handling
            switch event.Key
                case 'space'
                    app.StartPauseButtonPushed();
                case 'r'
                    app.ResetButtonPushed();
                case 'c'
                    app.ConfigButtonPushed();
                case 'h'
                    app.showHelp();
                case 'tab'
                    app.toggleMode();
            end
        end
        
        function StartPauseButtonPushed(app, ~)
            % Start/Pause button callback
            if ~app.isRunning
                app.startSession();
            else
                if app.isPaused
                    app.resumeSession();
                else
                    app.pauseSession();
                end
            end
        end
        
        function ResetButtonPushed(app, ~)
            % Reset button callback
            if app.isRunning
                choice = uiconfirm(app.UIFigure, 'Are you sure you want to reset the current session?', 'Confirm Reset', ...
                    'Options', {'Yes', 'No'}, 'DefaultOption', 2);
                if strcmp(choice, 'Yes')
                    app.resetSession();
                end
            else
                app.resetSession();
            end
        end
        
        function ConfigButtonPushed(app, ~)
            % Config button callback
            app.openConfigDialog();
        end
        
        function DataButtonPushed(app, ~)
            % Data button callback
            app.openDataViewer();
        end
        
        function HardwareButtonPushed(app, ~)
            % Hardware button callback
            app.openHardwareTest();
        end
        
        % Menu callbacks
        function LoadConfigMenuSelected(app, ~)
            app.loadConfiguration();
        end
        
        function SaveConfigMenuSelected(app, ~)
            app.saveConfiguration();
        end
        
        function ExportDataMenuSelected(app, ~)
            app.exportSessionData();
        end
        
        function ExitMenuSelected(app, ~)
            app.UIFigureCloseRequest();
        end
        
        function HardwareTestMenuSelected(app, ~)
            app.openHardwareTest();
        end
        
        function SimModeMenuSelected(app, ~)
            app.toggleSimulationMode();
        end
        
        function AboutMenuSelected(app, ~)
            app.showAbout();
        end
        
        % New parameter editing callbacks
        function ApplyParamsButtonPushed(app, ~)
            app.applyParameterChanges();
        end
        
        function SaveParamsButtonPushed(app, ~)
            app.saveParametersToFile();
        end
        
        function LoadParamsButtonPushed(app, ~)
            app.loadParametersFromFile();
        end
    end
    % App logic methods
    methods (Access = private)
        
        function initializeApplication(app)
            % Initialize application
            try
                % Create configuration object
                app.config = core.Config();
                
                % Create adaptive controller
                app.adaptive = core.AdaptiveController();
                
                % Create IO backend based on configuration
                if app.config.simulation_mode
                    app.ioBackend = io.SimKeyboardBackend(app.config);
                else
                    app.ioBackend = io.ArduinoBackend(app.config);
                end
                
                % Create data logger
                app.logger = core.TrialLogger(app.config);
                
                % Create state machine
                app.stateMachine = core.TaskStateMachine(app.config, app.ioBackend, ...
                                                        app.logger, app.adaptive);
                
                % Set up event listeners
                app.setupEventListeners();
                
                % Create UI update timer
                app.updateTimer = timer('ExecutionMode', 'fixedRate', ...
                                       'Period', 1/app.config.ui_refresh_rate, ...
                                       'TimerFcn', @(~,~) app.updateUI());
                
                % Update UI
                app.updateConfigurationDisplay();
                app.updateEditFieldsFromConfig();
                
                fprintf('Application initialization completed\n');
                
            catch ME
                uialert(app.UIFigure, sprintf('Initialization failed: %s', ME.message), 'Error');
            end
        end
        
        function setupEventListeners(app)
            % Set up event listeners
            app.stateChangeListener = addlistener(app.stateMachine, 'StateChanged', ...
                @(src, event) app.onStateChanged(event));
            
            app.trialCompleteListener = addlistener(app.stateMachine, 'TrialCompleted', ...
                @(src, event) app.onTrialCompleted(event));
            
            app.parameterAdjustListener = addlistener(app.adaptive, 'ParameterAdjusted', ...
                @(src, event) app.onParameterAdjusted(event));
        end
        
        function startSession(app)
            % Start session
            try
                % Update configuration from UI
                app.updateConfigFromUI();
                
                % Recreate state machine with updated configuration to ensure all changes are applied
                app.stateMachine = core.TaskStateMachine(app.config, app.ioBackend, ...
                                                        app.logger, app.adaptive);
                app.setupEventListeners();
                
                % Start state machine
                app.stateMachine.startSession();
                
                % Start timer
                start(app.updateTimer);
                
                % Update state
                app.isRunning = true;
                app.isPaused = false;
                app.sessionStartTime = tic;
                
                % Update UI
                app.StartPauseButton.Text = 'Pause';
                app.StartPauseButton.BackgroundColor = [1 0.5 0];
                
                fprintf('Session started\n');
                
            catch ME
                uialert(app.UIFigure, sprintf('Session start failed: %s', ME.message), 'Error');
            end
        end
        
        function pauseSession(app)
            % Pause session
            app.stateMachine.pauseSession();
            app.isPaused = true;
            
            app.StartPauseButton.Text = 'Resume';
            app.StartPauseButton.BackgroundColor = [0 0.8 0];
            
            fprintf('Session paused\n');
        end
        
        function resumeSession(app)
            % Resume session
            app.stateMachine.resumeSession();
            app.isPaused = false;
            
            app.StartPauseButton.Text = 'Pause';
            app.StartPauseButton.BackgroundColor = [1 0.5 0];
            
            fprintf('Session resumed\n');
        end
        
        function resetSession(app)
            % Reset session
            if app.isRunning
                app.stateMachine.stopSession();
                stop(app.updateTimer);
            end
            
            app.isRunning = false;
            app.isPaused = false;
            app.resultHistory = [];
            
            % Reset UI
            app.StartPauseButton.Text = 'Start';
            app.StartPauseButton.BackgroundColor = [0 0.8 0];
            
            app.CurrentStateLabel.Text = 'Status: ITI';
            app.CountdownLabel.Text = 'Countdown: --';
            app.TrialProgressLabel.Text = 'Trial: 0/500';
            
            % Reset LEDs
            app.updateLEDDisplay([false, false, false], false);
            
            % Clear results display
            cla(app.ResultsAxes);
            
            % Reset statistics
            app.updateStatisticsDisplay([], 0);
            
            fprintf('Session reset\n');
        end
        
        function updateUI(app)
            % Update UI display
            if ~app.isRunning
                return;
            end
            
            % Update state machine
            app.stateMachine.update(toc(app.sessionStartTime));
            
            % Update status display
            state = app.stateMachine.getCurrentState();
            app.CurrentStateLabel.Text = sprintf('Status: %s', core.TaskState.toString(state));
            
            % Update trial progress
            trialIndex = app.stateMachine.getTrialIndex();
            app.TrialProgressLabel.Text = sprintf('Trial: %d/%d', trialIndex, app.config.max_trials);
            
            % Update LED display
            if app.ioBackend.isHardwareConnected()
                ledStates = app.ioBackend.getLEDStates();
                rewardActive = app.ioBackend.isRewardActive();
                app.updateLEDDisplay(ledStates, rewardActive);
            end
            
            % Update statistics
            results = app.stateMachine.getTrialResults();
            itiErrors = app.stateMachine.getITIErrorCount();
            app.updateStatisticsDisplay(results, itiErrors);
            
            % Check if session is ended
            if ~app.stateMachine.isSessionRunning()
                app.resetSession();
            end
        end
        
        function updateLEDDisplay(app, ledStates, rewardActive)
            % Update LED display
            leds = {app.LED1Lamp, app.LED2Lamp, app.LED3Lamp};
            colors = {[0 1 0], [0 1 0], [0 1 0]};  % Green
            
            for i = 1:3
                if ledStates(i)
                    leds{i}.Color = colors{i};
                else
                    leds{i}.Color = [0.5 0.5 0.5];  % Gray
                end
            end
            
            if rewardActive
                app.RewardLamp.Color = [1 0 0];  % Red
            else
                app.RewardLamp.Color = [0.5 0.5 0.5];  % Gray
            end
        end
        
        function updateStatisticsDisplay(app, results, itiErrors)
            % Update statistics display
            if isempty(results)
                totalTrials = 0;
                correctTrials = 0;
                errorTrials = 0;
                accuracy = 0;
                noPressErrors = 0;
                wrongButtonErrors = 0;
                holdTooLongErrors = 0;
                prematurePressErrors = 0;
            else
                totalTrials = length(results);
                correctTrials = sum(results == 0);
                errorTrials = sum(results > 0);
                accuracy = correctTrials / totalTrials * 100;
                
                noPressErrors = sum(results == 1);
                wrongButtonErrors = sum(results == 2);
                holdTooLongErrors = sum(results == 3);
                prematurePressErrors = sum(results == 4);
            end
            
            app.StatsTable.Data = {
                'Total Trials', num2str(totalTrials);
                'Correct Trials', sprintf('%d (%.1f%%)', correctTrials, accuracy);
                'Error Trials', num2str(errorTrials);
                'No Press', num2str(noPressErrors);
                'Wrong Button', num2str(wrongButtonErrors);
                'Hold Too Long', num2str(holdTooLongErrors);
                'Premature Press', num2str(prematurePressErrors);
                'ITI Errors', num2str(itiErrors)
            };
        end
        
        function updateConfigurationDisplay(app)
            % Update configuration display
            app.SubjectIDField.Value = app.config.subject_id;
            app.SessionLabelField.Value = app.config.session_label;
            
            if strcmp(app.config.mode, 'sequence3')
                app.ModeDropDown.Value = 'Sequence-3';
            else
                app.ModeDropDown.Value = 'Shaping-1';
            end
            
            app.ParamsTable.Data = {
                'L1 Wait', sprintf('%.1fs', app.config.wait_L1);
                'L2 Wait', sprintf('%.1fs', app.config.wait_L2);
                'L3 Wait', sprintf('%.1fs', app.config.wait_L3);
                'I1 Interval', sprintf('%.1fs', app.config.I1);
                'I2 Interval', sprintf('%.1fs', app.config.I2);
                'Release Window', sprintf('%.1fs', app.config.release_window);
                'ITI Correct', sprintf('%.1f±%.1fs', app.config.ITI_fixed_correct, app.config.ITI_rand_correct);
                'ITI Error', sprintf('%.1f±%.1fs', app.config.ITI_fixed_error, app.config.ITI_rand_error)
            };
        end
        
        function updateConfigFromUI(app)
            % Update configuration from UI - including all parameter edits
            app.config.subject_id = app.SubjectIDField.Value;
            app.config.session_label = app.SessionLabelField.Value;
            
            if strcmp(app.ModeDropDown.Value, 'Sequence-3')
                app.config.mode = 'sequence3';
            else
                app.config.mode = 'shaping1';
            end
            
            % Update all timing parameters from edit fields
            if ~isempty(app.WaitL1Field)
                app.config.wait_L1 = app.WaitL1Field.Value;
                app.config.wait_L2 = app.WaitL2Field.Value;
                app.config.wait_L3 = app.WaitL3Field.Value;
                app.config.I1 = app.I1Field.Value;
                app.config.I2 = app.I2Field.Value;
                app.config.release_window = app.ReleaseWindowField.Value;
                app.config.ITI_fixed_correct = app.ITICorrectFixedField.Value;
                app.config.ITI_rand_correct = app.ITICorrectRandField.Value;
                app.config.ITI_fixed_error = app.ITIErrorFixedField.Value;
                app.config.ITI_rand_error = app.ITIErrorRandField.Value;
                
                % Update shaping mode settings
                switch app.ShapingLEDDropDown.Value
                    case 'LED1'
                        app.config.shaping_led = 1;
                    case 'LED2'
                        app.config.shaping_led = 2;
                    case 'LED3'
                        app.config.shaping_led = 3;
                end
                
                app.config.shaping_random_mode = app.ShapingRandomCheckBox.Value;
                app.config.sequence_random_mode = app.SequenceRandomCheckBox.Value;
                
                % Parse sequence order
                orderStr = app.SequenceOrderField.Value;
                orderStr = strrep(orderStr, ' ', ''); % Remove spaces
                orderParts = split(orderStr, ',');
                customSequence = [];
                for i = 1:length(orderParts)
                    num = str2double(orderParts{i});
                    if ~isnan(num) && num >= 1 && num <= 3
                        customSequence(end+1) = num;
                    end
                end
                
                if ~isempty(customSequence)
                    app.config.custom_sequence = customSequence;
                    app.customSequenceOrder = customSequence;
                else
                    app.config.custom_sequence = [1, 2, 3];
                    app.customSequenceOrder = [1, 2, 3];
                end
            end
            
            % Generate session label
            app.config.generateSessionLabel();
            app.SessionLabelField.Value = app.config.session_label;
        end
        
        function onStateChanged(app, eventData)
            % State change event handling
            % UI updates are handled in updateUI
        end
        
        function onTrialCompleted(app, eventData)
            % Trial completion event handling
            trialData = eventData.TrialData;
            result = trialData.result_code;
            
            % Update result history
            app.resultHistory(end+1) = result;

            
            % Update results display
            app.updateResultsDisplay();
            
            fprintf('Trial %d completed: %s\n', trialData.trial_index, trialData.result_text);
        end
        
        function onParameterAdjusted(app, eventData)
            % Parameter adjustment event handling
            performance = eventData.Performance;
            
            % Update parameter display
            app.updateConfigurationDisplay();
            
            fprintf('Parameter adaptive adjustment: Accuracy %.1f%%\n', performance.accuracy * 100);
        end
        
        % function updateResultsDisplay(app)
        %     % Update results strip display
        %     cla(app.ResultsAxes);
        % 
        %     if isempty(app.resultHistory)
        %         return;
        %     end
        % 
        %     numResults = length(app.resultHistory);
        % 
        %     for i = 1:numResults
        %         result = app.resultHistory(i);
        %         color = app.resultColors(result + 1, :);
        % 
        %         rectangle(app.ResultsAxes, 'Position', [i-0.4, 0.6, 0.8, 0.8], ...
        %                  'FaceColor', color, 'EdgeColor', 'black');
        %     end
        % 
        %     app.ResultsAxes.XLim = [0.5 app.maxResultsDisplay + 0.5];
        %     app.ResultsAxes.YLim = [0.5 1.5];
        % end
        % 
        function updateResultsDisplay(app)
            a = app.ResultsAxes;
            cla(a);
        
            if isempty(app.resultHistory)
                title(a, 'No data');  return;
            end
        
            % —— 全部试次 —— 
            results = app.resultHistory;
            n = numel(results);
        
            % 轴像素大小 → 自动列数；行数按“装下全部”计算
            axpos = getpixelposition(a, true);   % [x y w h] px
            wpx   = max(1, axpos(3));
            hpx   = max(1, axpos(4));
            s     = max(2, round(app.resultSquarePx)); % 目标方块边长(px)
            g     = max(0, round(app.resultGapPx));    % 间隙(px)
        
            cols  = max(1, floor((wpx + g) / (s + g)));   % 每行方块数（自适应）
            rows  = max(1, ceil(n / cols));               % 行数（放下全部）
        
            % —— 大数据走热图（快得多）——
            if n > 2500
                v = results(:)' + 1;                 % 1..5
                if numel(v) < rows*cols
                    v(end+1:rows*cols) = 0;          % 0=空白
                end
                M = reshape(v, cols, rows)';         % rows x cols
                imagesc(a, M);
                axis(a,'ij'); axis(a,'tight'); box(a,'on');
                colormap(a, [1 1 1; app.resultColors]);  % 0白色, 1..5按你的颜色
                a.CLim = [0 5];
                a.XTick = []; a.YTick = [];
                title(a, sprintf('All %d trials (heatmap)', n));
                return;
            end
        
            % —— 小矩形绘制路径 —— 
            pad = min(0.45, (g / max(1,(s + g))) / 2); % 像素间隙换算成单元内边距比例
            a.XTick = []; a.YTick = [];
            a.XLim = [0, cols]; a.YLim = [0, rows];
            axis(a,'ij'); box(a,'on');
        
            hold(a,'on');
            for k = 1:n
                c = mod(k-1, cols) + 1;
                r = ceil(k / cols);
                x = (c-1) + pad;   y = (r-1) + pad;
                w = 1 - 2*pad;     h = 1 - 2*pad;
        
                color = app.resultColors(results(k)+1, :); % 0..4 → 1..5
                rectangle(a, 'Position', [x,y,w,h], ...
                             'FaceColor', color, 'EdgeColor','k', 'LineWidth',0.5);
            end
            hold(a,'off');
        
            title(a, sprintf('All %d trials (~%dx%d squares target %dpx)', n, rows, cols, s));
        end
        function cleanupApplication(app)
            % Clean up application
            try
                % Stop timer
                if ~isempty(app.updateTimer) && isvalid(app.updateTimer)
                    stop(app.updateTimer);
                    delete(app.updateTimer);
                end
                
                % Stop session
                if app.isRunning
                    app.stateMachine.stopSession();
                end
                
                % Clean up backend
                if ~isempty(app.ioBackend)
                    app.ioBackend.cleanup();
                end
                
                % Clean up data logger
                if ~isempty(app.logger)
                    app.logger.cleanup();
                end
                
                fprintf('Application cleanup completed\n');
                
            catch ME
                warning('Error occurred during cleanup: %s', ME.message);
            end
        end
        
        % Helper methods
        function loadConfiguration(app)
            % Load configuration file
            [file, path] = uigetfile('*.json', 'Select Configuration File', 'config');
            if file ~= 0
                try
                    app.config.loadFromFile(fullfile(path, file));
                    app.updateConfigurationDisplay();
                    uialert(app.UIFigure, 'Configuration loaded successfully', 'Success', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, sprintf('Configuration load failed: %s', ME.message), 'Error');
                end
            end
        end
        
        function saveConfiguration(app)
            % Save configuration file
            [file, path] = uiputfile('*.json', 'Save Configuration File', 'config.json');
            if file ~= 0
                try
                    app.updateConfigFromUI();
                    app.config.saveToFile(fullfile(path, file));
                    uialert(app.UIFigure, 'Configuration saved successfully', 'Success', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, sprintf('Configuration save failed: %s', ME.message), 'Error');
                end
            end
        end
        
        function openConfigDialog(app)
            % Open configuration dialog
            % A detailed configuration dialog can be created here
            uialert(app.UIFigure, 'Configuration dialog functionality to be implemented', 'Information');
        end
        
        function openDataViewer(app)
            % Open data viewer
            uialert(app.UIFigure, 'Data viewer functionality to be implemented', 'Information');
        end
        
        function openHardwareTest(app)
            % Open hardware test
            uialert(app.UIFigure, 'Hardware test functionality to be implemented', 'Information');
        end
        
        function showHelp(app)
            % Show help information
            helpText = {
                'Shortcuts:',
                'Space - Start/Pause',
                'R - Reset',
                'C - Config',
                'H - Help',
                'Tab - Toggle Mode',
                '',
                'If using simulation mode:',
                'Q - Button1',
                'W - Button2',
                'E - Button3'
            };
            
            uialert(app.UIFigure, strjoin(helpText, newline), 'Help');
        end
        
        function showAbout(app)
            % Show about information
            aboutText = {
                'Three-Key Sequence Mouse Training Task',
                'Version 1.0',
                '',
                'Behavioral experiment platform developed with MATLAB',
                'Supports Arduino Due hardware control',
                '',
                'Developer: Shen'
            };
            
            uialert(app.UIFigure, strjoin(aboutText, newline), 'About');
        end
        
        function toggleMode(app)
            % Toggle mode
            if strcmp(app.ModeDropDown.Value, 'Sequence-3')
                app.ModeDropDown.Value = 'Shaping-1';
            else
                app.ModeDropDown.Value = 'Sequence-3';
            end
        end
        
        function toggleSimulationMode(app)
            % Toggle simulation mode
            if app.isRunning
                uialert(app.UIFigure, 'Please stop the current session first', 'Warning');
                return;
            end
            
            % Switch mode
            app.config.simulation_mode = ~app.config.simulation_mode;
            
            % Clean up old IO backend
            if ~isempty(app.ioBackend)
                app.ioBackend.cleanup();
            end
            
            % Create IO backend based on new configuration
            if app.config.simulation_mode
                app.ioBackend = io.SimKeyboardBackend(app.config);
                uialert(app.UIFigure, 'Switched to simulation mode\nKey mapping: Q=Button1, W=Button2, E=Button3', 'Information', 'Icon', 'info');
            else
                app.ioBackend = io.ArduinoBackend(app.config);
                uialert(app.UIFigure, 'Switched to hardware mode', 'Information', 'Icon', 'info');
            end
            
            % Recreate state machine
            app.stateMachine = core.TaskStateMachine(app.config, app.ioBackend, ...
                                                    app.logger, app.adaptive);
            
            % Reset event listeners
            app.setupEventListeners();
        end
        
        function exportSessionData(app)
            % Export session data
            if isempty(app.logger) || isempty(app.logger.getSessionPath())
                uialert(app.UIFigure, 'No data to export', 'Notice');
                return;
            end
            
            [file, path] = uiputfile({'*.xlsx', 'Excel Files'; '*.mat', 'MAT Files'}, ...
                                     'Export Data', 'session_data');
            if file ~= 0
                [~, ~, ext] = fileparts(file);
                try
                    switch ext
                        case '.xlsx'
                            app.logger.exportData('excel', path);
                        case '.mat'
                            app.logger.exportData('mat', path);
                    end
                    uialert(app.UIFigure, 'Data export successful', 'Success', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, sprintf('Data export failed: %s', ME.message), 'Error');
                end
            end
        end
        
        function applyParameterChanges(app)
            % Apply parameter changes from edit fields to config
            if app.isRunning
                uialert(app.UIFigure, 'Cannot change parameters while session is running', 'Warning');
                return;
            end
            
            try
                % Update configuration from edit fields
                app.config.wait_L1 = app.WaitL1Field.Value;
                app.config.wait_L2 = app.WaitL2Field.Value;
                app.config.wait_L3 = app.WaitL3Field.Value;
                app.config.I1 = app.I1Field.Value;
                app.config.I2 = app.I2Field.Value;
                app.config.release_window = app.ReleaseWindowField.Value;
                app.config.ITI_fixed_correct = app.ITICorrectFixedField.Value;
                app.config.ITI_rand_correct = app.ITICorrectRandField.Value;
                app.config.ITI_fixed_error = app.ITIErrorFixedField.Value;
                app.config.ITI_rand_error = app.ITIErrorRandField.Value;
                
                % Update shaping mode settings
                switch app.ShapingLEDDropDown.Value
                    case 'LED1'
                        app.config.shaping_led = 1;
                    case 'LED2'
                        app.config.shaping_led = 2;
                    case 'LED3'
                        app.config.shaping_led = 3;
                end
                
                app.config.shaping_random_mode = app.ShapingRandomCheckBox.Value;
                app.config.sequence_random_mode = app.SequenceRandomCheckBox.Value;
                
                % Parse sequence order
                orderStr = app.SequenceOrderField.Value;
                orderStr = strrep(orderStr, ' ', ''); % Remove spaces
                orderParts = split(orderStr, ',');
                app.customSequenceOrder = [];
                for i = 1:length(orderParts)
                    num = str2double(orderParts{i});
                    if ~isnan(num) && num >= 1 && num <= 3
                        app.customSequenceOrder(end+1) = num;
                    end
                end
                
                if isempty(app.customSequenceOrder)
                    app.customSequenceOrder = [1, 2, 3];
                    app.SequenceOrderField.Value = '1,2,3';
                end
                
                % Update config with sequence order
                app.config.custom_sequence = app.customSequenceOrder;
                
                % Validate configuration
                app.config.validateConfig();
                
                % Recreate state machine with new configuration
                app.stateMachine = core.TaskStateMachine(app.config, app.ioBackend, ...
                                                        app.logger, app.adaptive);
                
                % Reset event listeners
                app.setupEventListeners();
                
                % Update display
                app.updateConfigurationDisplay();
                app.updateEditFieldsFromConfig();
                
                uialert(app.UIFigure, 'Parameters applied successfully', 'Success', 'Icon', 'success');
                
            catch ME
                uialert(app.UIFigure, sprintf('Parameter application failed: %s', ME.message), 'Error');
            end
        end
        
        function saveParametersToFile(app)
            % Save current parameters to file
            [file, path] = uiputfile('*.json', 'Save Parameters', 'parameters.json');
            if file ~= 0
                try
                    % Apply current edit field values first
                    app.applyParameterChanges();
                    
                    % Save to file
                    app.config.saveToFile(fullfile(path, file));
                    uialert(app.UIFigure, 'Parameters saved successfully', 'Success', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, sprintf('Parameter save failed: %s', ME.message), 'Error');
                end
            end
        end
        
        function loadParametersFromFile(app)
            % Load parameters from file
            if app.isRunning
                uialert(app.UIFigure, 'Cannot load parameters while session is running', 'Warning');
                return;
            end
            
            [file, path] = uigetfile('*.json', 'Load Parameters');
            if file ~= 0
                try
                    % Load configuration
                    app.config.loadFromFile(fullfile(path, file));
                    
                    % Recreate state machine with new configuration
                    app.stateMachine = core.TaskStateMachine(app.config, app.ioBackend, ...
                                                            app.logger, app.adaptive);
                    
                    % Reset event listeners
                    app.setupEventListeners();
                    
                    % Update displays
                    app.updateConfigurationDisplay();
                    app.updateEditFieldsFromConfig();
                    
                    uialert(app.UIFigure, 'Parameters loaded successfully', 'Success', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, sprintf('Parameter load failed: %s', ME.message), 'Error');
                end
            end
        end
        
        function updateEditFieldsFromConfig(app)
            % Update edit fields from current configuration
            app.WaitL1Field.Value = app.config.wait_L1;
            app.WaitL2Field.Value = app.config.wait_L2;
            app.WaitL3Field.Value = app.config.wait_L3;
            app.I1Field.Value = app.config.I1;
            app.I2Field.Value = app.config.I2;
            app.ReleaseWindowField.Value = app.config.release_window;
            app.ITICorrectFixedField.Value = app.config.ITI_fixed_correct;
            app.ITICorrectRandField.Value = app.config.ITI_rand_correct;
            app.ITIErrorFixedField.Value = app.config.ITI_fixed_error;
            app.ITIErrorRandField.Value = app.config.ITI_rand_error;
            
            % Update shaping LED dropdown
            switch app.config.shaping_led
                case 1
                    app.ShapingLEDDropDown.Value = 'LED1';
                case 2
                    app.ShapingLEDDropDown.Value = 'LED2';
                case 3
                    app.ShapingLEDDropDown.Value = 'LED3';
            end
            
            % Update sequence order field
            if ~isempty(app.config.custom_sequence)
                app.customSequenceOrder = app.config.custom_sequence;
                app.SequenceOrderField.Value = strjoin(string(app.customSequenceOrder), ',');
            else
                app.customSequenceOrder = [1, 2, 3];
                app.SequenceOrderField.Value = '1,2,3';
            end
            
            % Update checkboxes
            app.ShapingRandomCheckBox.Value = app.config.shaping_random_mode;
            app.SequenceRandomCheckBox.Value = app.config.sequence_random_mode;
        end
    end
    
    % Component initialization methods are defined above
    
    % App creation and deletion
    methods (Access = public)
        
        function app = TaskTrainApp()
            % Constructor
            
            % Create UI components
            createComponents(app);
            
            % Register app to App Designer
            registerApp(app, app.UIFigure);
            
            % Execute startup function
            runStartupFcn(app, @startupFcn);
            
            if nargout == 0
                clear app
            end
        end
        
        function delete(app)
            % Destructor
            % Clean up application
            app.cleanupApplication();
            
            % Delete UI components
            delete(app.UIFigure);
        end
    end
end