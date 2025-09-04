# TaskTrain MATLAB - Three-Key Sequence Mouse Training Task

## Project Overview

TaskTrain MATLAB is a professional behavioral experiment system for three-key sequence mouse training tasks. This system is developed based on MATLAB and Arduino, providing precise timing control, real-time data recording, and adaptive algorithm support.

## Key Features

### 🎯 Core Functions
- **Dual Training Modes**: Sequence-3 (three-key sequence) and Shaping-1 (single button shaping)
- **Precise State Machine**: Complete state transition logic (ITI → L1_WAIT → I1 → L2_WAIT → I2 → L3_WAIT → REWARD)
- **Dual Time Window Release Detection**: Accurate button release timing judgment
- **Complete Error Coding System**: 5 result types (0-4)
- **Real-time Data Recording**: JSON detailed data + CSV summary data
- **Adaptive Algorithm**: Dynamic parameter adjustment based on performance

### 🔧 Hardware Support
- **Arduino Due**: Main control board
- **LED Indicators**: 3 visual feedback lights
- **Photoelectric Switches**: 3 button input detection
- **Solenoid Valve**: Reward delivery system
- **Simulation Mode**: Keyboard simulation (Q/W/E keys)

### 📊 Data Analysis
- **Real-time Statistics**: Success rate, reaction time, error analysis
- **Visual Display**: Trial result strips, LED status indicators
- **Data Export**: Multiple format support (JSON, CSV, MAT)
- **Session Summary**: Automatic statistical analysis and reporting

## System Requirements

### Software Environment
- **MATLAB**: R2019b or higher
- **Operating System**: Windows 10/11 (tested)
- **Optional Toolboxes**:
  - MATLAB Support Package for Arduino Hardware
  - Instrument Control Toolbox

### Hardware Requirements
- **Arduino Due** development board (optional, for hardware mode)
- **USB Cable** for Arduino connection
- **LED Lights** × 3 (optional)
- **Photoelectric Switches** × 3 (optional)
- **Solenoid Valve** × 1 (optional)

## Quick Start

### Installation
1. Extract project files to MATLAB path
2. Connect Arduino hardware (optional)
3. Open MATLAB and navigate to project directory

### Launch Program
```matlab
% Method 1: Use main entry point
TaskTrain()

% Method 2: Launch GUI directly
app = gui.TaskTrainApp();

% Method 3: Core function testing
test_core()
```

### First Run
1. **Select Mode**: Choose "Hardware" or "Simulation" mode
2. **Configure Parameters**: Set subject ID, session parameters
3. **Start Training**: Click "Start Session" button
4. **Monitor Progress**: View real-time statistics and trial results

## Usage Instructions

### Training Modes

#### Sequence-3 Mode
- **Objective**: Train mice to press three buttons in sequence (1→2→3)
- **State Flow**: ITI → L1_WAIT → I1 → L2_WAIT → I2 → L3_WAIT → REWARD
- **Success Criteria**: Complete sequence within time limits
- **Error Types**: Early release, wrong button, timeout

#### Shaping-1 Mode
- **Objective**: Basic single button training
- **State Flow**: Simplified single button press detection
- **Success Criteria**: Press and hold button for specified duration
- **Progressive Training**: Gradually increase difficulty

### Operation Methods

#### Hardware Mode
- **Button 1/2/3**: Physical photoelectric switches
- **LED 1/2/3**: Visual feedback indicators
- **Reward**: Solenoid valve activation
- **Connection**: Arduino Due via USB

#### Simulation Mode
- **Q/W/E Keys**: Simulate buttons 1/2/3
- **Screen Display**: Virtual LED status
- **Audio Feedback**: Reward sound simulation
- **No Hardware Required**: Pure software simulation

### Interface Guide

#### Main Panels
1. **Session Information**: Subject ID, session time, trial count
2. **Current Status**: Real-time state display and LED indicators
3. **Recent Trial Results**: Color-coded result strips
4. **Current Parameters**: Active training parameters
5. **Statistics**: Success rate, reaction time analysis
6. **Control Panel**: Start/pause/reset session controls

#### Menu Functions
- **File Menu**: Configuration management, data export
- **Edit Menu**: Parameter editing, preferences
- **View Menu**: Display options, window management
- **Tools Menu**: Hardware testing, calibration
- **Help Menu**: User guide, about information

## Data File Structure

### Directory Organization
```
data/
├── <SubjectID>/
│   ├── <SessionID>/
│   │   ├── trial_0001.json      # Detailed trial data
│   │   ├── trial_0002.json
│   │   ├── ...
│   │   ├── session_summary.csv   # Session summary
│   │   └── session_analysis.json # Statistical analysis
│   └── ...
└── ...
```

### Data Formats

#### Trial Data (JSON)
```json
{
  "trial_number": 1,
  "start_time": "2024-01-15T10:30:45.123",
  "end_time": "2024-01-15T10:30:47.456",
  "result_code": 0,
  "state_sequence": [...],
  "button_events": [...],
  "timing_data": {...},
  "parameters": {...}
}
```

#### Session Summary (CSV)
| Column | Description |
|--------|-------------|
| trial_number | Trial sequence number |
| result_code | Result type (0-4) |
| reaction_time | Response time (ms) |
| sequence_duration | Total sequence time |
| error_type | Error classification |

## Configuration Parameters

### Core Parameters
- **l1_wait_time**: Button 1 hold duration (ms)
- **i1_time**: Interval 1 duration (ms)
- **l2_wait_time**: Button 2 hold duration (ms)
- **i2_time**: Interval 2 duration (ms)
- **l3_wait_time**: Button 3 hold duration (ms)
- **reward_time**: Reward delivery duration (ms)
- **iti_time**: Inter-trial interval (ms)

### Adaptive Parameters
- **adaptive_enabled**: Enable adaptive algorithm
- **performance_window**: Performance evaluation window
- **adjustment_threshold**: Parameter adjustment threshold
- **adjustment_step**: Adjustment step size

### Hardware Parameters
- **arduino_port**: Arduino serial port
- **baud_rate**: Communication baud rate
- **debounce_time**: Button debounce time
- **led_brightness**: LED brightness level

## Adaptive Algorithm

### Performance Evaluation
- **Success Rate**: Percentage of successful trials
- **Reaction Time**: Average response time
- **Error Pattern**: Error type distribution
- **Trend Analysis**: Performance trend over time

### Adjustment Strategies
1. **Difficulty Increase**: Reduce time windows when performance is good
2. **Difficulty Decrease**: Increase time windows when performance is poor
3. **Fine Tuning**: Small adjustments for stable performance
4. **Error-specific**: Targeted adjustments based on error types

### Adjustment History
- **Parameter Changes**: Record all parameter modifications
- **Performance Impact**: Track adjustment effectiveness
- **Rollback Capability**: Revert unsuccessful adjustments

## Troubleshooting

### Common Issues

#### Hardware Connection
- **Problem**: Arduino not detected
- **Solution**: Check USB connection, verify port settings
- **Verification**: Use "Tools → Hardware Test"

#### Timing Issues
- **Problem**: Inaccurate timing
- **Solution**: Close unnecessary programs, check system performance
- **Optimization**: Use dedicated computer for experiments

#### Data Recording
- **Problem**: Data not saved
- **Solution**: Check file permissions, verify disk space
- **Recovery**: Check backup files in temp directory

### Error Codes
| Code | Description | Possible Causes |
|------|-------------|----------------|
| 0 | Success | Normal completion |
| 1 | Early Release | Released button too early |
| 2 | Wrong Button | Pressed incorrect button |
| 3 | Timeout | Exceeded time limit |
| 4 | ITI Error | Action during inter-trial interval |

### Performance Optimization
- **Close Background Programs**: Minimize system load
- **Disable Antivirus Real-time Scan**: Reduce interference
- **Use SSD Storage**: Improve data writing speed
- **Dedicated Hardware**: Use separate computer for experiments

## Technical Architecture

### Module Structure
```
+core/                    # Core modules
├── TaskStateMachine.m    # State machine core
├── Config.m              # Configuration management
├── TrialLogger.m         # Data recording
└── AdaptiveController.m  # Adaptive control

+io/                      # IO abstraction layer
├── IOBackend.m           # Abstract interface
├── ArduinoBackend.m      # Arduino hardware control
└── SimKeyboardBackend.m  # Keyboard simulation

+gui/                     # GUI interface
└── TaskTrainApp.m        # Main application
```

### Design Patterns
- **State Machine Pattern**: Core logic control
- **Observer Pattern**: Event notification system
- **Strategy Pattern**: Multiple IO backend support
- **Factory Pattern**: Backend creation and management

### Performance Specifications
- **Timing Precision**: Millisecond-level control
- **Response Time**: UI updates at 30FPS, hardware control at 100Hz
- **Data Integrity**: Real-time saving with exception safety
- **Long-term Stability**: Support for continuous multi-hour operation

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

### Documentation
- **User Manual**: This README file
- **Technical Documentation**: See documents/ directory
- **API Reference**: MATLAB help documentation

### Contact Information
- **Project Repository**: [GitHub Repository]
- **Issue Reporting**: Use GitHub Issues
- **Technical Support**: Contact development team

### Contributing
- **Bug Reports**: Submit via GitHub Issues
- **Feature Requests**: Discuss in GitHub Discussions
- **Code Contributions**: Submit Pull Requests
- **Documentation**: Help improve documentation

---

**Version**: 1.0.0  
**Last Updated**: January 2024  
**Status**: ✅ Production Ready