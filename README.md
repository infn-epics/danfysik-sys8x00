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
   ```bash
   git clone <repository-url>
   cd danfysik-sys8x00
```

