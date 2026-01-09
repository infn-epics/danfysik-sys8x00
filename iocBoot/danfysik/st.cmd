#!../../bin/linux-x86_64/danfysiksys8x00

#- EPICS IOC startup script for Danfysik System SYS8X00 Power Supply
#- StreamDevice based IOC

< envPaths

cd "${TOP}"

# Environment variables
epicsEnvSet("STREAM_PROTOCOL_PATH", "${TOP}/db")
epicsEnvSet("BOOT", "${TOP}/iocBoot/${IOC}")

# Device configuration - MODIFY THESE PARAMETERS
epicsEnvSet("DEVICE_PREFIX", "PS:DANFYSIK:01")     # Device PV prefix
epicsEnvSet("PS_ADDRESS", "1")                      # Power supply address (0-63)
epicsEnvSet("IMAX", "100.0")                        # Maximum current in Amperes
epicsEnvSet("VMAX", "50.0")                         # Maximum voltage in Volts

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

#===============================================================================
# OPTION 2: Ethernet/TCP Communication (Terminal Server or Ethernet-Serial Converter)
#===============================================================================
# Configure IP address and port
epicsEnvSet("PS_IP", "192.168.1.100")              # IP address of power supply or terminal server
epicsEnvSet("PS_PORT", "4001")                     # TCP port number

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

## Register all support components
dbLoadDatabase "dbd/danfysiksys8x00.dbd"
danfysiksys8x00_registerRecordDeviceDriver pdbbase

#===============================================================================
# Database Loading
#===============================================================================

# Load the main Danfysik power supply database
dbLoadRecords("db/danfysik.template", "DEVICE=$(DEVICE_PREFIX),PORT=DANFYSIK_PORT,ADDR=$(PS_ADDRESS),IMAX=$(IMAX),VMAX=$(VMAX),PREC=3")

# Load UNIMAG interface (simplified bipolar current control with automatic polarity switching)
# Comment out if UNIMAG interface is not needed
epicsEnvSet("UNIMAG_PREFIX", "$(DEVICE_PREFIX):UNIMAG")
dbLoadRecords("db/danfysik_unimag.template", "DEVICE=$(DEVICE_PREFIX),UNIMAG=$(UNIMAG_PREFIX),IMAX=$(IMAX)")

# Optional: Load additional instances for multiple power supplies
# Uncomment and modify as needed for multiple units
#epicsEnvSet("DEVICE_PREFIX2", "PS:DANFYSIK:02")
#epicsEnvSet("PS_ADDRESS2", "2") 
#dbLoadRecords("db/danfysik.template", "DEVICE=$(DEVICE_PREFIX2),PORT=DANFYSIK_PORT,ADDR=$(PS_ADDRESS2),IMAX=$(IMAX),VMAX=$(VMAX),PREC=3")
#epicsEnvSet("UNIMAG_PREFIX2", "$(DEVICE_PREFIX2):UNIMAG")
#dbLoadRecords("db/danfysik_unimag.template", "DEVICE=$(DEVICE_PREFIX2),UNIMAG=$(UNIMAG_PREFIX2),IMAX=$(IMAX)")

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
# UNIMAG State Machine (SNL Sequencer)
#===============================================================================
# This sequencer provides automatic polarity switching for bipolar operation
# Comment out if UNIMAG interface is not needed or sequencer is not available

# Load and start UNIMAG control sequencer
# The sequencer handles automatic polarity changes when crossing zero
seq danfysikUnimagControl, "device=$(DEVICE_PREFIX), unimag=$(UNIMAG_PREFIX), debug=1"

# Optional: Start additional sequencers for multiple power supplies  
#seq danfysikUnimagControl, "device=$(DEVICE_PREFIX2), unimag=$(UNIMAG_PREFIX2), debug=1"

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

cd "${TOP}/iocBoot/${IOC}"

# Initialize the IOC
iocInit

#===============================================================================
# Post-initialization setup
#===============================================================================

# Initialize the power supply for remote operation
# This sends the remote control command and enables text error messages
# Wait a moment for IOC to fully initialize
epicsThreadSleep 2.0

# Set power supply to remote mode and enable error reporting
dbpf "$(DEVICE_PREFIX):INIT_REMOTE" 1
dbpf "$(DEVICE_PREFIX):ERROR_TEXT" 1

# Set power supply address (if different from default)
# dbpf "$(DEVICE_PREFIX):ADDR_SP" $(PS_ADDRESS)

# Optional: Set some reasonable defaults
# dbpf "$(DEVICE_PREFIX):RAMP_RATE_SP" 5.0          # 5 A/s ramp rate
# dbpf "$(DEVICE_PREFIX):REMOTE" 1                  # Ensure remote control

# Print some helpful information
echo "==============================================================================="
echo "Danfysik SYS8X00 Power Supply IOC Started Successfully"  
echo "Device Prefix: $(DEVICE_PREFIX)"
echo "PS Address: $(PS_ADDRESS)"
echo "Max Current: $(IMAX) A"
echo "Max Voltage: $(VMAX) V"
echo ""
echo "Key PVs:"
echo "  Current Setpoint:    $(DEVICE_PREFIX):I_SP"
echo "  Current Readback:    $(DEVICE_PREFIX):I_RB"  
echo "  Voltage Readback:    $(DEVICE_PREFIX):V_RB"
echo "  Power Control:       $(DEVICE_PREFIX):POWER_SP"
echo "  Status:              $(DEVICE_PREFIX):STATUS"
echo "  Remote Control:      $(DEVICE_PREFIX):REMOTE"
echo ""
echo "UNIMAG Interface PVs:"
echo "  UNIMAG Current SP:   $(UNIMAG_PREFIX):I_SP (bipolar -$(IMAX) to +$(IMAX) A)"
echo "  UNIMAG Current RB:   $(UNIMAG_PREFIX):I_RB"
echo "  UNIMAG State:        $(UNIMAG_PREFIX):STATE"
echo "  UNIMAG Status:       $(UNIMAG_PREFIX):STATUS"
echo ""
echo "Web Interface (if CSS-BOY/Phoebus available):"
echo "  Main Panel: $(DEVICE_PREFIX)"
echo "==============================================================================="

#===============================================================================
# Optional: Start caRepeater (for CA clients)
#===============================================================================
# Uncomment if needed for your setup
# system("caRepeater &")

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