GHDL=ghdl
WORK=vhdlbaselib
WORKDIR_NAME=work
# Warning!!! Below line has to be finished with '/' to prevent from recompile
# the all library again and again
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)/
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
HDL_LIB_TOP_DIR=../
DEPS=hdl_lib_top


#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = axis_m_switch_tb axis_data_drop_tb axis_buf_tb

# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
# OBJECTS = $(SOURCES:.vhd=.o)
OBJECTS = $(addprefix $(WORKDIR), dword_filler.o connector.o axis_buf.o \
multi_s_axis_sw.o axis_sw_pkg.o axis_m_switch.o axis_data_drop.o dword_serializer.o\
dword_filler.o native_fifo_to_axi.o axis_fall_through.o )
TB_OBJECTS = $(addprefix $(WORKDIR), $(TARGET:=.o))
all: $(OBJECTS)

### Main target
$(TARGET): $(WORKDIR) $(DEPS) $(TB_OBJECTS)
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
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR) WORKDIR=$(WORKDIR)
	
# To remove generated files
clean:
	rm -rf $(TARGET) $(OBJECTS) $(WORKDIR) *.cf *.ghw

