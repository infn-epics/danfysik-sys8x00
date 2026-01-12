#!../../bin/linux-x86_64/danfysiksys8x00

< envPaths
epicsEnvSet("IOC", "danfysik")

## Register all support components
dbLoadDatabase "$(TOP)/dbd/danfysiksys8x00.dbd"
danfysiksys8x00_registerRecordDeviceDriver pdbbase

# Environment variables
epicsEnvSet("STREAM_PROTOCOL_PATH", "${TOP}/db")
epicsEnvSet("BOOT", "${TOP}/iocBoot/${IOC}")

# Device configuration - MODIFY THESE PARAMETERS
epicsEnvSet("DEVICE_PREFIX", "BTF:MAG:DANFYSIK")     # Base device PV prefix
epicsEnvSet("PS_IP", "192.168.192.40")              # IP address of power supply server
epicsEnvSet("PS_PORT", "4005")                      # TCP port number


# Communication configuration - CHOOSE ONE OF THE OPTIONS BELOW

#===============================================================================
# OPTION 1: Serial/RS232 Communication
#===============================================================================
# Configure serial port parameters
#epicsEnvSet("SERIAL_PORT", "/dev/ttyUSB0")         # Serial port device
#epicsEnvSet("BAUD_RATE", "9600")                   # Baud rate (19200,9600,4800,2400,1200,600,300,150)
#epicsEnvSet("DATA_BITS", "8")                      # Data bits
#epicsEnvSet("STOP_BITS", "1")                      # Stop bits  
#epicsEnvSet("PARITY", "none")                      # Parity (none, even, odd)
#epicsEnvSet("FLOW_CONTROL", "none")                # Flow control (none, hardware)

# Create serial port driver
#drvAsynSerialPortConfigure("DANFYSIK_PORT", "$(SERIAL_PORT)", 0, 0, 0)
#asynSetOption("DANFYSIK_PORT", -1, "baud", "$(BAUD_RATE)")
#asynSetOption("DANFYSIK_PORT", -1, "bits", "$(DATA_BITS)")
#asynSetOption("DANFYSIK_PORT", -1, "stop", "$(STOP_BITS)")
#asynSetOption("DANFYSIK_PORT", -1, "parity", "$(PARITY)")
#asynSetOption("DANFYSIK_PORT", -1, "clocal", "Y")
#asynSetOption("DANFYSIK_PORT", -1, "crtscts", "$(FLOW_CONTROL=N)")

# Create TCP/IP port driver  
drvAsynIPPortConfigure("DANFYSIK_PORT", "$(PS_IP):$(PS_PORT)", 0, 0, 0)

#===============================================================================
# OPTION 3: RS-485/RS-422 via Serial-to-Ethernet Converter
#===============================================================================  
# Use the same TCP configuration as Option 2, but ensure your converter
# is properly configured for RS-485/RS-422 operation

#===============================================================================
# Common asyn configuration
#===============================================================================

# Set trace masks for debugging (comment out for production)
#asynSetTraceMask("DANFYSIK_PORT", -1, 0x09)       # Enable traceError and traceFlow  
#asynSetTraceIOMask("DANFYSIK_PORT", -1, 0x02)     # Enable traceIOHex

# Configure asyn for StreamDevice
#asynSetOption("DANFYSIK_PORT", -1, "disconnectOnReadTimeout", "Y")


#===============================================================================
# Database Loading
#===============================================================================

# Load databases for each power supply device

# QUATM002
epicsEnvSet("DEVICE_QUATM002", "$(DEVICE_PREFIX):QUATM002")
epicsEnvSet("ADDR_QUATM002", "10")
epicsEnvSet("IMAX_QUATM002", "100.0")
epicsEnvSet("VMAX_QUATM002", "25.0")
dbLoadRecords("$(TOP)/db/danfysik.template", "DEVICE=$(DEVICE_QUATM002),PORT=DANFYSIK_PORT,ADDR=$(ADDR_QUATM002),IMAX=$(IMAX_QUATM002),VMAX=$(VMAX_QUATM002),PREC=3")
dbLoadRecords("$(TOP)/db/danfysik_unimag.template", "DEVICE=$(DEVICE_QUATM002),IMAX=$(IMAX_QUATM002)")

# QUATM003
epicsEnvSet("DEVICE_QUATM003", "$(DEVICE_PREFIX):QUATM003")
epicsEnvSet("ADDR_QUATM003", "11")
epicsEnvSet("IMAX_QUATM003", "100.0")
epicsEnvSet("VMAX_QUATM003", "25.0")
dbLoadRecords("$(TOP)/db/danfysik.template", "DEVICE=$(DEVICE_QUATM003),PORT=DANFYSIK_PORT,ADDR=$(ADDR_QUATM003),IMAX=$(IMAX_QUATM003),VMAX=$(VMAX_QUATM003),PREC=3")
dbLoadRecords("$(TOP)/db/danfysik_unimag.template", "DEVICE=$(DEVICE_QUATM003),IMAX=$(IMAX_QUATM003)")

# DHRTB101
# epicsEnvSet("DEVICE_DHRTB101", "$(DEVICE_PREFIX):DHRTB101")
# epicsEnvSet("ADDR_DHRTB101", "29")
# epicsEnvSet("IMAX_DHRTB101", "100.0")
# epicsEnvSet("VMAX_DHRTB101", "25.0")
# dbLoadRecords("$(TOP)/db/danfysik.template", "DEVICE=$(DEVICE_DHRTB101),PORT=DANFYSIK_PORT,ADDR=$(ADDR_DHRTB101),IMAX=$(IMAX_DHRTB101),VMAX=$(VMAX_DHRTB101),PREC=3")
# dbLoadRecords("$(TOP)/db/danfysik_unimag.template", "DEVICE=$(DEVICE_DHRTB101),IMAX=$(IMAX_DHRTB101)")

#===============================================================================
# Optional: Load autosave/restore functionality
#===============================================================================
# Uncomment if you have autosave support compiled in

#epicsEnvSet("AUTOSAVE_PATH", "${BOOT}/autosave")
#set_savefile_path("$(AUTOSAVE_PATH)")
#set_requestfile_path("$(AUTOSAVE_PATH)")

# Auto-save settings every 30 seconds  
#create_monitor_set("danfysik_settings.req", 30, "DEVICE=$(DEVICE_PREFIX)")

#===============================================================================
# Optional: Load EPICS archiver configuration
#===============================================================================
# Uncomment if you want to configure archiving

#dbLoadRecords("$(AUTOSAVE)/db/save_restoreStatus.db", "P=$(DEVICE_PREFIX):")

#===============================================================================
# Optional: Load access security
#===============================================================================
# Uncomment and modify if you need access security

#asSetFilename("${TOP}/iocBoot/access.acf")

#===============================================================================
# IOC Initialization
#===============================================================================

# Initialize the IOC
iocInit


#===============================================================================
# UNIMAG State Machine (SNL Sequencer)
#===============================================================================
# This sequencer provides automatic polarity switching for bipolar operation

# Load and start UNIMAG control sequencers for each device
seq danfysikUnimagControl, "device=$(DEVICE_QUATM002), debug=1"
seq danfysikUnimagControl, "device=$(DEVICE_QUATM003), debug=1"
# seq danfysikUnimagControl, "device=$(DEVICE_DHRTB101), debug=1"

#===============================================================================
# Post-initialization setup
#===============================================================================

# Initialize the power supplies for remote operation
# This sends the remote control command and enables text error messages
# Wait a moment for IOC to fully initialize
epicsThreadSleep 2.0

# Set power supplies to remote mode and enable error reporting
dbpf "$(DEVICE_QUATM002):INIT_REMOTE" 1
dbpf "$(DEVICE_QUATM002):ERROR_TEXT" 1
dbpf "$(DEVICE_QUATM003):INIT_REMOTE" 1
dbpf "$(DEVICE_QUATM003):ERROR_TEXT" 1
# dbpf "$(DEVICE_DHRTB101):INIT_REMOTE" 1
# dbpf "$(DEVICE_DHRTB101):ERROR_TEXT" 1

# Optional: Set some reasonable defaults
# dbpf "$(DEVICE_PREFIX):RAMP_RATE_SP" 5.0          # 5 A/s ramp rate
# dbpf "$(DEVICE_PREFIX):REMOTE" 1                  # Ensure remote control

#===============================================================================
# Optional: Load and start sequencer programs  
#===============================================================================
# Uncomment if you have State Notation Language (SNL) programs

#seq "danfysik_sequence", "DEVICE=$(DEVICE_PREFIX)"

#===============================================================================
# Optional: Start Channel Access security
#===============================================================================
# Uncomment if using CA security
# asInit()

#===============================================================================
# OPI Display Launcher
#===============================================================================
# Launch operator interface displays (requires Phoebus or CSS-BOY)
# Uncomment to open displays automatically at IOC startup
# export DISPLAY_BUILDER_OPI_TOP=$(TOP)/opi
# phoebus --resource $(TOP)/opi/danfysik_launcher.bob &