GHDL=ghdl
WORK=vhdlbaselib
WORKDIR=work
PKG_WORK_DIR=$(shell pwd)/$(WORKDIR)
SYNC_BLOCK_ARCH ?= infer

# Default objects
OBJECTS = $(addprefix $(WORKDIR), sync_block.o)

# Chose architecture, set add object according to it
ifeq ($(SYNC_BLOCK_ARCH), xilinx)
  ifndef XIL_LIB_DIR
  $(error XIL_LIB_DIR is not set)
  endif
  override GHDLFLAGS += -P$(XIL_LIB_DIR)
  OBJECTS += $(addprefix $(WORKDIR), sync_block_xilinx.o)
endif

ifeq ($(SYNC_BLOCK_ARCH), infer)
	OBJECTS += $(addprefix $(WORKDIR), sync_block_infer.o)
else
	$(error SYNC_BLOCK_ARCH wrong value. Please set 'xilinx' or 'infer')
endif
#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
#TARGET = dword_filler_tb

# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
# OBJECTS = $(SOURCES:.vhd=.o)
all: $(OBJECTS)

### Main target
$(TARGET): $(WORKDIR) $(DEPS) $(OBJECTS)
#	$(CC) $(filter-out $(TARGET:=.o), $(OBJECTS)) $@.o -o $@
	$(GHDL) -e $(GHDLFLAGS) $@

### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
# create workdir	
$(WORKDIR):
	mkdir $@
	
# compile hdl lib pckages into workidr
#hdl_lib_pkg:
#	make -C $(PKG_DIR) WORKDIR=$(PKG_WORK_DIR)
	
# To remove generated files
clean:
	#make -C $(PKG_DIR) clean WORKDIR=$(PKG_WORK_DIR)
	rm -rf $(TARGET) $(OBJECTS) $(WORKDIR) *.cf

