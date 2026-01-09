# Danfysik SYS8X00 Power Supply EPICS IOC

This IOC provides comprehensive control and monitoring for Danfysik System SYS8X00 power supplies using EPICS StreamDevice.

## Features

- **Complete Protocol Implementation**: All documented Danfysik SYS8X00 commands implemented
- **Multiple Communication Options**: Serial RS-232/RS-422, TCP/IP via terminal server
- **Real-time Monitoring**: Current, voltage, temperature, internal power supplies  
- **Status Monitoring**: 24-bit status string with individual fault indicators
- **Polarity Control**: Support for units equipped with polarity reversal
- **Ramping Control**: Configurable ramp rates and end points
- **Multi-unit Support**: Address-based communication for multiple power supplies
- **Safety Features**: Power interlocks, error handling, emergency shutdown
- **High Resolution**: Support for high-resolution current measurements

## Quick Start

### 1. Configuration

Edit the startup script [iocBoot/danfysik/st.cmd](iocBoot/danfysik/st.cmd) and configure:

```bash
# Device configuration
epicsEnvSet("DEVICE_PREFIX", "PS:DANFYSIK:01")     # PV prefix
epicsEnvSet("PS_ADDRESS", "1")                     # Power supply address (0-63)  
epicsEnvSet("IMAX", "100.0")                       # Maximum current (A)
epicsEnvSet("VMAX", "50.0")                        # Maximum voltage (V)

# Communication - choose one:

# Option 1: Serial
epicsEnvSet("SERIAL_PORT", "/dev/ttyUSB0")
epicsEnvSet("BAUD_RATE", "9600")

# Option 2: TCP/IP  
epicsEnvSet("PS_IP", "192.168.1.100")
epicsEnvSet("PS_PORT", "4001")
```

### 2. Build and Run

```bash
make clean && make
cd iocBoot/danfysik
../../bin/linux-x86_64/danfysiksys8x00 st.cmd
```

### 3. Test Operation

```bash
# Check connection
caget PS:DANFYSIK:01:CONNECTED

# Read current
caget PS:DANFYSIK:01:I_RB

# Set current to 10A  
caput PS:DANFYSIK:01:I_SP 10.0

# Power on
caput PS:DANFYSIK:01:POWER_SP 1

# Check status
caget PS:DANFYSIK:01:STATUS
```

## Process Variables (PVs)

### Basic Control
- `$(DEVICE):POWER_SP` - Power on/off control
- `$(DEVICE):RESET` - Reset interlocks  
- `$(DEVICE):REMOTE` - Remote/local control
- `$(DEVICE):GOFF` - Global soft shutdown

### Current Control
- `$(DEVICE):I_SP` - Current setpoint (A)
- `$(DEVICE):I_SP_RB` - Current setpoint readback (A)
- `$(DEVICE):I_RB` - Output current readback (A)
- `$(DEVICE):I_HIRES_RB` - High-resolution current (A)

### Voltage Monitoring  
- `$(DEVICE):V_RB` - Output voltage readback (V)

### Ramping
- `$(DEVICE):RAMP_RATE_SP` - Ramp rate (A/s)
- `$(DEVICE):RAMP_RATE_RB` - Ramp rate readback (A/s)
- `$(DEVICE):RAMP_END_SP` - Ramp end current (A)
- `$(DEVICE):RAMP_END_RB` - Ramp end readback (A)

### Polarity (if equipped)
- `$(DEVICE):POL_SP` - Polarity select (Positive/Negative)
- `$(DEVICE):POL_RB` - Polarity readback (+/-/N/O)

### Status & Monitoring
- `$(DEVICE):STATUS` - 24-bit status string  
- `$(DEVICE):CTRL_MODE` - Control mode (REM/LOC)
- `$(DEVICE):CTRL_STATE` - Detailed control state
- `$(DEVICE):CONNECTED` - Connection status

### Internal Monitoring
- `$(DEVICE):P15V_RB` - +15V supply (V)
- `$(DEVICE):M15V_RB` - -15V supply (V)  
- `$(DEVICE):P5V_RB` - +5V supply (V)
- `$(DEVICE):TEMP_DELTA_RB` - Temperature delta (°C)
- `$(DEVICE):VCE_RB` - Transistor Vce (V)
- `$(DEVICE):TESLA_RB` - Tesla field (T, if equipped)

### Device Information
- `$(DEVICE):INFO` - Power supply info (serial, model)
- `$(DEVICE):VERSION` - Firmware version
- `$(DEVICE):ADDR_SP/RB` - MPS address

## Communication Protocol

The IOC implements the complete Danfysik SYS8X00 serial protocol:

### Command Structure
- **Termination**: Commands end with CR, responses with LF+CR
- **Addressing**: Support for addresses 0-63 for multi-unit systems
- **Error Handling**: Detects "?BELL" error indicator

### Key Commands Implemented
- `N/F` - Power on/off
- `WA/RA` - Write/read current setpoint (DAC based)
- `AD 0-9` - Read ADC channels (current, voltage, supplies, temperature)
- `PO/PO+/PO-` - Polarity control
- `S1` - Read 24-bit status string
- `REM/LOC` - Remote/local control
- `WR/RR` - Write/read ramp speed
- `RS` - Reset interlocks

## Multi-Unit Configuration  

For multiple power supplies on the same communication link:

1. Use different addresses for each unit (0-63)
2. Add multiple template instantiations:

```bash
# st.cmd additions
dbLoadRecords("db/danfysik.template", "DEVICE=PS:DANFYSIK:01,PORT=DANFYSIK_PORT,ADDR=1,IMAX=100.0,VMAX=50.0")
dbLoadRecords("db/danfysik.template", "DEVICE=PS:DANFYSIK:02,PORT=DANFYSIK_PORT,ADDR=2,IMAX=200.0,VMAX=60.0") 
```

Or use the substitutions file:
```bash
dbLoadTemplate("db/danfysik.substitutions")
```

## Troubleshooting

### Connection Issues
1. Check serial port permissions: `ls -l /dev/ttyUSB0`
2. Verify baud rate matches power supply setting
3. Enable asyn tracing in st.cmd:
   ```bash
   asynSetTraceMask("DANFYSIK_PORT", -1, 0x09)
   asynSetTraceIOMask("DANFYSIK_PORT", -1, 0x02)  
   ```

### Communication Issues
1. Check power supply is in remote mode
2. Verify correct address is selected  
3. Check for interlock conditions preventing operation
4. Monitor status string for error indicators

### Current Control Issues
1. Ensure power supply is powered on (`POWER_SP = 1`)
2. Check for interlocks in status string
3. Verify current limits (`IMAX` parameter)
4. Check polarity setting if equipped

## Safety Considerations

⚠️ **WARNING**: This IOC controls high-power equipment. Always:

1. **Verify Limits**: Set `IMAX` and `VMAX` correctly for your hardware
2. **Test Safely**: Start with low current values
3. **Monitor Status**: Check status string for fault conditions  
4. **Emergency Stop**: Use `GOFF` for safe shutdown
5. **Interlock Safety**: Never bypass hardware interlocks
6. **Remote Lock**: Use `RLOCK` to prevent local panel interference

## Files Structure

```
danfysik-sys8x00/
├── streamdeviceApp/
│   └── Db/
│       ├── danfysik.proto         # StreamDevice protocol
│       ├── danfysik.template      # Database template  
│       └── danfysik.substitutions # Substitution examples
├── iocBoot/
│   └── danfysik/
│       ├── st.cmd                 # Startup script
│       ├── envPaths              # Environment paths
│       └── Makefile              # Boot makefile
└── docs/
    ├── README.md                 # This file
    └── Danfysik-SYS8X00-clean.txt # Protocol documentation
```

## Protocol Reference

Based on: **Danfysik System SYS8X00 Command Reference** 
Document: P80303ML / P80303WH

For detailed protocol information, see [docs/Danfysik-SYS8X00-clean.txt](docs/Danfysik-SYS8X00-clean.txt)

## Support

For issues or questions:
1. Check the EPICS StreamDevice documentation
2. Review asyn driver documentation  
3. Consult Danfysik power supply manual
4. Enable debug tracing for protocol analysis

## License

This IOC is provided under the same terms as EPICS Base.