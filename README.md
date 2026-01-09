# Danfysik SYS8X00 Power Supply EPICS IOC

This IOC provides complete control and monitoring for the Danfysik System SYS8X00 series power supplies using EPICS StreamDevice. It includes both standard power supply control and an advanced UNIMAG interface for simplified bipolar operation.

## Features

### Standard Power Supply Control
- **Current Control**: Precise current setting with DAC-based control (0-65535 range)
- **Voltage Monitoring**: Real-time output voltage monitoring  
- **Polarity Control**: Support for positive/negative polarity switching (if equipped)
- **Ramping**: Configurable current ramping with rate and end point control
- **Status Monitoring**: Comprehensive status reporting including power, remote mode, regulation status
- **Error Handling**: Text-based error messages and error code reporting
- **Internal Monitoring**: Supply voltages (+15V, +24V) and temperature monitoring
- **Communication**: Support for Serial (RS-232/485/422) and TCP/IP connections

### UNIMAG Interface
- **Bipolar Current Control**: Simplified interface accepting signed current values (-IMAX to +IMAX)
- **Automatic Polarity Switching**: SNL state machine handles polarity changes automatically when crossing zero
- **State Machine Control**: Robust sequencing with error recovery and timeout handling
- **Debug Support**: Configurable debug levels and comprehensive diagnostics
- **Statistics**: Sequence counting and error tracking

## Communication Interfaces

### Supported Protocols
- **Serial Communication**: RS-232, RS-485, RS-422
  - Baud rates: 150 to 19200 bps
  - Standard serial port or USB-to-serial adapters
- **TCP/IP Communication**: 
  - Direct Ethernet connection (if available)
  - Serial-to-Ethernet terminal servers
  - Modbus TCP (future enhancement)

### Protocol Implementation
- Full implementation of Danfysik SYS8X00 command set
- Address-based communication (0-63 device addresses)
- Checksum validation for reliable communication
- Automatic retry and error recovery

## Getting Started

### Prerequisites
- EPICS Base 7.0+ (tested with 7.0.8)
- EPICS modules:
  - asyn 4-44+
  - StreamDevice 2.8.24+
  - sequencer 2.2+ (for UNIMAG interface)

### Installation
1. Clone this repository:
   ```

2. Configure your EPICS environment:
   ```bash
   # Set EPICS_BASE and module paths in configure/RELEASE
   vi configure/RELEASE
   ```

3. Build the IOC:
   ```bash
   make clean && make
   ```

4. Configure your power supply settings:
   ```bash
   cd iocBoot/danfysik
   # Edit st.cmd to set your device parameters
   vi st.cmd
   ```

### Configuration

#### Basic Configuration in st.cmd
```bash
# Device configuration - MODIFY THESE PARAMETERS
epicsEnvSet("DEVICE_PREFIX", "PS:DANFYSIK:01")     # Device PV prefix
epicsEnvSet("PS_ADDRESS", "1")                      # Power supply address (0-63)
epicsEnvSet("IMAX", "100.0")                        # Maximum current in Amperes
epicsEnvSet("VMAX", "50.0")                         # Maximum voltage in Volts
```

#### Communication Setup
**Option 1: Serial Communication**
```bash
epicsEnvSet("SERIAL_PORT", "/dev/ttyUSB0")
epicsEnvSet("BAUD_RATE", "9600")
drvAsynSerialPortConfigure("DANFYSIK_PORT", "$(SERIAL_PORT)", 0, 0, 0)
```

**Option 2: TCP/IP Communication**
```bash
epicsEnvSet("PS_IP", "192.168.1.100")
epicsEnvSet("PS_PORT", "4001")
drvAsynIPPortConfigure("DANFYSIK_PORT", "$(PS_IP):$(PS_PORT)", 0, 0, 0)
```

### Running the IOC
```bash
cd iocBoot/danfysik
../../bin/linux-x86_64/danfysiksys8x00 st.cmd
```

## Process Variable Reference

### Standard Power Supply PVs
| PV Name | Type | Description | Units |
|---------|------|-------------|-------|
| `$(DEVICE):I_SP` | ao | Current setpoint | A |
| `$(DEVICE):I_RB` | ai | Current readback | A |
| `$(DEVICE):V_RB` | ai | Voltage readback | V |
| `$(DEVICE):POWER_SP` | bo | Power control (0=Off, 1=On) | - |
| `$(DEVICE):POWER_RB` | bi | Power status readback | - |
| `$(DEVICE):POL_SP` | mbbo | Polarity setpoint | - |
| `$(DEVICE):POL_RB` | mbbi | Polarity readback | - |
| `$(DEVICE):REMOTE` | bo | Remote/Local control | - |
| `$(DEVICE):STATUS` | stringin | Status text | - |
| `$(DEVICE):ERROR_MSG` | stringin | Error message | - |
| `$(DEVICE):RAMP_RATE_SP` | ao | Ramp rate | A/s |
| `$(DEVICE):RAMP_END_SP` | ao | Ramp end point | A |
| `$(DEVICE):DAC_SP` | longout | DAC setpoint (0-65535) | - |
| `$(DEVICE):DAC_RB` | longin | DAC readback | - |

### UNIMAG Interface PVs
| PV Name | Type | Description | Units | Range |
|---------|------|-------------|-------|-------|
| `$(DEVICE):UNIMAG:I_SP` | ao | Bipolar current setpoint | A | -IMAX to +IMAX |
| `$(DEVICE):UNIMAG:I_RB` | ai | Bipolar current readback | A | -IMAX to +IMAX |
| `$(DEVICE):UNIMAG:ENABLE` | bo | Enable UNIMAG interface | - | 0/1 |
| `$(DEVICE):UNIMAG:STATE` | stringin | State machine state | - | TEXT |
| `$(DEVICE):UNIMAG:STATUS` | stringin | Status message | - | TEXT |
| `$(DEVICE):UNIMAG:BUSY` | bi | Sequencing active | - | 0/1 |
| `$(DEVICE):UNIMAG:TIMEOUT` | ao | Sequence timeout | s | 1-300 |
| `$(DEVICE):UNIMAG:DEBUG_LEVEL` | mbbo | Debug output level | - | 0-3 |
| `$(DEVICE):UNIMAG:ABORT` | bo | Abort current sequence | - | - |
| `$(DEVICE):UNIMAG:SEQ_COUNT` | longin | Total sequences executed | - | - |
| `$(DEVICE):UNIMAG:ERROR_COUNT` | longin | Error count | - | - |

### Monitoring and Diagnostics PVs
| PV Name | Type | Description | Units |
|---------|------|-------------|-------|
| `$(DEVICE):SUPPLY_15V` | ai | +15V supply voltage | V |
| `$(DEVICE):SUPPLY_24V` | ai | +24V supply voltage | V |
| `$(DEVICE):TEMP` | ai | Internal temperature | °C |
| `$(DEVICE):ADC0_RB` | longin | Raw ADC channel 0 (current) | - |
| `$(DEVICE):ADC1_RB` | longin | Raw ADC channel 1 (voltage) | - |
| `$(DEVICE):STATUS_RAW` | longin | Raw status word | - |
| `$(DEVICE):ERROR_CODE` | longin | Numeric error code | - |

## Operator Interface (OPI)

### Available Interfaces
The IOC includes comprehensive operator interfaces built for CSS-BOY/Phoebus:

1. **Main Power Supply Panel** (`danfysik_ps.bob`)
   - Complete power supply control and monitoring
   - Current/voltage control with ramping
   - Status monitoring and error display
   - Power control and polarity switching

2. **UNIMAG Interface Panel** (`danfysik_ps_unimag.bob`)
   - Simplified bipolar current control
   - State machine status monitoring
   - Sequence control and diagnostics
   - Quick-set buttons for common values

3. **Expert/Debug Panel** (`danfysik_ps_expert.bob`)
   - Raw ADC values and status bits
   - Direct command interface
   - Calibration parameters
   - Communication diagnostics

4. **Launcher Panel** (`danfysik_launcher.bob`)
   - Central launch point for all interfaces
   - Configurable macros for different setups
   - Documentation and configuration notes

### Opening OPI Panels
1. Launch your CSS-BOY or Phoebus application
2. Open the launcher panel: `opi/danfysik_launcher.bob`
3. Set appropriate macros (DEVICE, IMAX, VMAX)
4. Click the desired interface button

## UNIMAG Interface Operation

### What is UNIMAG?
UNIMAG (Universal Magnet Interface) is a simplified bipolar current control system that:
- Accepts signed current setpoints (-IMAX to +IMAX Amperes)
- Automatically handles polarity switching when crossing zero
- Provides seamless bipolar operation without manual intervention
- Includes robust error handling and recovery mechanisms

### State Machine Operation
The UNIMAG interface uses an SNL (State Notation Language) state machine with the following states:

1. **IDLE**: Waiting for setpoint changes
2. **CHECK_POLARITY**: Determining if polarity change is needed  
3. **RAMP_TO_ZERO**: Ramping current to zero before polarity change
4. **POWER_OFF**: Turning off power supply for safe polarity change
5. **CHANGE_POLARITY**: Switching polarity relays/contacts
6. **POWER_ON**: Re-enabling power supply after polarity change
7. **SET_CURRENT**: Setting the new current value

### Usage Example
```bash
# Enable UNIMAG interface
caput PS:DANFYSIK:01:UNIMAG:ENABLE 1

# Set positive current (no polarity change needed)
caput PS:DANFYSIK:01:UNIMAG:I_SP 50.0

# Set negative current (automatic polarity change)
caput PS:DANFYSIK:01:UNIMAG:I_SP -30.0

# Monitor the state machine
caget PS:DANFYSIK:01:UNIMAG:STATE
caget PS:DANFYSIK:01:UNIMAG:STATUS
```

## Troubleshooting

### Common Issues

1. **Communication Errors**
   - Check cable connections and pinout
   - Verify baud rate and communication parameters
   - Check power supply address setting
   - Monitor communication with asyn trace: `asynSetTraceMask("PORT", -1, 0x09)`

2. **UNIMAG Interface Not Working**
   - Ensure sequencer module is compiled and loaded
   - Check that SNL program is started in st.cmd
   - Verify UNIMAG template is loaded
   - Check debug output: `caput PS:DANFYSIK:01:UNIMAG:DEBUG_LEVEL 2`

3. **Current/Voltage Readings Incorrect**  
   - Verify calibration parameters (gain/offset)
   - Check maximum current/voltage settings
   - Ensure proper scaling in database template

4. **Power Supply Not Responding**
   - Check remote mode is enabled
   - Verify power supply is in proper operating state
   - Check for error conditions on power supply
   - Use expert panel for direct command testing

### Debug Commands
```bash
# Enable asyn communication trace
asynSetTraceMask("DANFYSIK_PORT", -1, 0x09)
asynSetTraceIOMask("DANFYSIK_PORT", -1, 0x02)

# Monitor UNIMAG state machine
camonitor PS:DANFYSIK:01:UNIMAG:STATE
camonitor PS:DANFYSIK:01:UNIMAG:STATUS

# Send direct commands (expert use)
caput PS:DANFYSIK:01:DIRECT_CMD "S1"
caget PS:DANFYSIK:01:DIRECT_RESP
```

## Files and Directory Structure

```
danfysik-sys8x00/
├── README.md                          # This documentation
├── Makefile                           # Top-level build file
├── configure/                         # Build configuration
├── streamdeviceApp/
│   ├── src/                          # Source code and SNL programs
│   │   ├── Makefile                  # Application build file
│   │   └── danfysikUnimagControl.st  # UNIMAG state machine
│   └── Db/                           # Database templates
│       ├── danfysik.template         # Main power supply template
│       ├── danfysik_unimag.template  # UNIMAG interface template
│       └── danfysik.proto            # StreamDevice protocol
├── iocBoot/danfysik/                 # IOC startup directory
│   ├── st.cmd                        # Startup script
│   ├── envPaths                      # EPICS environment paths
│   └── danfysik_settings.req         # Autosave request file
└── opi/                              # Operator interface files
    ├── danfysik_ps.bob               # Main control panel
    ├── danfysik_ps_unimag.bob        # UNIMAG interface panel  
    ├── danfysik_ps_expert.bob        # Expert/debug panel
    ├── danfysik_launcher.bob          # Interface launcher
    └── settings_local.ini            # OPI configuration
```

## Development and Customization

### Adding New Commands
1. Add protocol definition to `db/danfysik.proto`
2. Add corresponding database records to `db/danfysik.template` 
3. Update OPI panels if needed
4. Test thoroughly with your power supply model

### Customizing UNIMAG Behavior
- Modify timeout values in `danfysik_unimag.template`
- Adjust state machine logic in `src/danfysikUnimagControl.st`
- Add custom sequence validation as needed

### Multi-Device Support
The IOC supports multiple power supplies on the same communication channel:
```bash
# Load additional instances in st.cmd
dbLoadRecords("db/danfysik.template", "DEVICE=PS:DANFYSIK:02,PORT=DANFYSIK_PORT,ADDR=2,...")
dbLoadRecords("db/danfysik_unimag.template", "DEVICE=PS:DANFYSIK:02,UNIMAG=PS:DANFYSIK:02:UNIMAG,...")
```

## References

- [Danfysik SYS8X00 Manual](https://www.danfysik.com)
- [EPICS StreamDevice Documentation](https://paulscherrerinstitute.github.io/StreamDevice/)
- [EPICS Base Documentation](https://docs.epics-controls.org/)
- [State Notation Language Guide](https://www-csr.bessy.de/control/SoftDist/sequencer/)
- [CSS-BOY/Phoebus OPI Documentation](https://control-system-studio.readthedocs.io/)

## Support

For issues, questions, or contributions:
- Check the troubleshooting section above
- Review EPICS community resources
- Submit issues via the project repository

## License

This project follows standard EPICS licensing terms. See individual source files for specific license information.bash
   git clone <repository-url>
   cd danfysik-sys8x00
```

