TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

PROD_IOC = danfysiksys8x00
# danfysiksys8x00.dbd will be created and installed
DBD += danfysiksys8x00.dbd

# danfysiksys8x00.dbd will be made up from these files:
danfysiksys8x00_DBD += base.dbd
danfysiksys8x00_DBD += stream.dbd ## streamdevice.dbd
danfysiksys8x00_DBD += asyn.dbd 
danfysiksys8x00_DBD += drvAsynIPPort.dbd
danfysiksys8x00_DBD += drvAsynSerialPort.dbd

# Add sequencer support for UNIMAG functionality
ifneq ($(SNCSEQ),)
danfysiksys8x00_DBD += seq.dbd
danfysiksys8x00_LIBS += seq pv
endif


# Include dbd files from all support applications:
#streamdevice_DBD += xxx.dbd

# Add all the support libraries needed by this IOC
#streamdevice_LIBS += xxx
danfysiksys8x00_LIBS += stream
danfysiksys8x00_LIBS += asyn


# streamdevice_registerRecordDeviceDriver.cpp derives from streamdevice.dbd
danfysiksys8x00_SRCS += danfysiksys8x00_registerRecordDeviceDriver.cpp

# Build the main IOC entry point on workstation OSs.
danfysiksys8x00_SRCS_DEFAULT += danfysiksys8x00Main.cpp
danfysiksys8x00_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#danfysiksys8x00_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# State Notation Language (SNL) support for UNIMAG sequencing
ifneq ($(SNCSEQ),)
danfysiksys8x00_DBD += snc.dbd
danfysiksys8x00_LIBS += seq pv
danfysiksys8x00_SRCS += danfysikUnimagControl.st
endif

# Finally link to the EPICS Base libraries
danfysiksys8x00_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

