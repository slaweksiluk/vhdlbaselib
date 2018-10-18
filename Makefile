VHDL_STD?=93
ifeq ($(VHDL_STD),08)
  FRELAX=-frelaxed-rules
endif
export GHDL = ghdl
WORK=vhdlbaselib
LIB_NAME=vhdlbaselib
#  Witthou overwride variables are passed from calling Mafile ALWAYS!
export WORKDIR = $(shell pwd)/$(LIB_NAME)/v$(VHDL_STD)/
#WORKDIR = $(shell pwd)/$(LIB_NAME)/
export GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) --std=$(VHDL_STD) $(FRELAX)
#GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
#GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
export XIL_LIB_DIR = $(shell cd ~ && pwd)/vhdl_vendors_libs/xilinx-ise/
# sub-makes options
SUBMAKE_FLAGS = -e -C
# subdirs
PACKAGES_DIR=packages
GENERATORS_DIR=generators
CONNECTORS_DIR=connectors
COUNTERS_DIR=counters
DETECTORS_DIR=detectors
SYNC_DIR=sync
PRBS_DIR=prbs
WISHBONE_DIR=wishbone
WBS_REG_DIR=$(WISHBONE_DIR)/wbs_reg
ATE_DIR=ate
BRIDGES_DIR=bridges
WIDTH_CONV_DIR=bus_conv
INTER_DIR=interconnects/
WB_PKGS_DIR=wishbone_pkgs/
FIFOS_DIR=fifos/
DECODERS_DIR=decoders/

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs
#TARGET = common_pkg_tb axis_test_env_tb
# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
#TB_OBJ = axis_test_env_tb.o common_pkg_tb.o

#all: $(TARGET)
all: $(WORKDIR)
	make $(SUBMAKE_FLAGS) $(WB_PKGS_DIR)
	make $(SUBMAKE_FLAGS) $(DETECTORS_DIR)
	make $(SUBMAKE_FLAGS) $(COUNTERS_DIR)
	make $(SUBMAKE_FLAGS) $(PACKAGES_DIR)
	make $(SUBMAKE_FLAGS) $(CONNECTORS_DIR)
	make $(SUBMAKE_FLAGS) $(FIFOS_DIR)
	make $(SUBMAKE_FLAGS) $(GENERATORS_DIR)
	make $(SUBMAKE_FLAGS) $(SYNC_DIR)
	make $(SUBMAKE_FLAGS) $(PRBS_DIR)
	make $(SUBMAKE_FLAGS) $(WISHBONE_DIR)
	make $(SUBMAKE_FLAGS) $(WBS_REG_DIR)
	make $(SUBMAKE_FLAGS) $(ATE_DIR)
	make $(SUBMAKE_FLAGS) $(BRIDGES_DIR)
	make $(SUBMAKE_FLAGS) $(WIDTH_CONV_DIR)
	make $(SUBMAKE_FLAGS) $(INTER_DIR)
	make $(SUBMAKE_FLAGS) $(DECODERS_DIR)

#import:
#	$(GHDL) -i $(GHDLFLAGS) --work=$(WORK) $(PACKAGES_DIR)/*.vhd
#	$(GHDL) -i $(GHDLFLAGS) --work=$(WORK) $(CONNECTORS_DIR)/*.vhd
#	$(GHDL) -i $(GHDLFLAGS) --work=$(WORK) $(GENERATORS_DIR)/*.vhd
#	$(GHDL) -i $(GHDLFLAGS) --work=$(WORK) $(GENERATORS_DIR)/*.vhd
### Main target
# wokdir var afeter object is for creating work dir
#$(TARGET): $(WORKDIR) $(DEPS)
##	$(CC) $(filter-out $(TARGET:=.o), $(OBJECTS)) $@.o -o $@
#	$(GHDL) -e $(GHDLFLAGS) $@
##	$(GHDL) -i $(GHDLFLAGS) $(SOURCES)
##	$(GHDL) -m $(GHDLFLAGS) $@


### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
#%.o: %.vhd
#	$(GHDL) -a $(GHDLFLAGS) $<

# create workdir
$(WORKDIR):
	mkdir -p $@

# To remove generated files
clean:
	rm -rf $(shell pwd)/$(LIB_NAME) $(OBJECTS) $(TARGET) *.cf

