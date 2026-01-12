TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

# Build an IOC support library
LIBRARY_IOC += danfysikSupport
# danfysikSupport.dbd will be created and installed
DBD += danfysikSupport.dbd

# danfysikSupport.dbd will be made up from these files:
danfysikSupport_DBD += base.dbd
danfysikSupport_DBD += stream.dbd ## streamdevice.dbd
danfysikSupport_DBD += asyn.dbd 
danfysikSupport_DBD += drvAsynIPPort.dbd
danfysikSupport_DBD += drvAsynSerialPort.dbd

# Install support dbd into <top>/dbd
# Include dbd for SNL program registrar
# SNL program source (built into support library)
danfysikSupport_SRCS += danfysikUnimagControl.st
# Link sequencer support and pv utilities into support library
danfysikSupport_LIBS += seq pv
# Link base IOC libs into support library
danfysikSupport_LIBS += $(EPICS_BASE_IOC_LIBS)

# Build the main IOC application
PROD_IOC = danfysiksys8x00

# danfysiksys8x00.dbd will be created and installed
DBD += danfysiksys8x00.dbd

# Ensure support dbd is built before main dbd
$(COMMON_DIR)/danfysiksys8x00.dbd: $(COMMON_DIR)/danfysikSupport.dbd

# danfysiksys8x00.dbd will be made up from these files:
danfysiksys8x00_DBD += base.dbd
danfysiksys8x00_DBD += stream.dbd ## streamdevice.dbd
danfysiksys8x00_DBD += asyn.dbd 
danfysiksys8x00_DBD += drvAsynIPPort.dbd
danfysiksys8x00_DBD += drvAsynSerialPort.dbd
danfysiksys8x00_DBD += danfysikSupport.dbd

# danfysiksys8x00_registerRecordDeviceDriver.cpp derives from danfysiksys8x00.dbd
danfysiksys8x00_SRCS += danfysiksys8x00_registerRecordDeviceDriver.cpp

# Build the main IOC entry point on workstation OSs.
danfysiksys8x00_SRCS_DEFAULT += danfysiksys8x00Main.cpp
danfysiksys8x00_SRCS_vxWorks += -nil-

# Link in the code from our support library
danfysiksys8x00_LIBS += danfysikSupport

# Add all the support libraries needed by this IOC
danfysiksys8x00_LIBS += stream
danfysiksys8x00_LIBS += asyn

# Finally link to the EPICS Base libraries
danfysiksys8x00_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

