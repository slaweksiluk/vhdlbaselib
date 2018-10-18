GHDL=ghdl
WORK=work
WORKDIR_NAME=work
# Warning!!! Below line has to be finished with '/' to prevent from recompile
# the all library again and again
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)/
HDL_LIB_TOP_DIR=../../
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) -P$(HDL_LIB_TOP_DIR)vhdlbaselib/

DEPS=hdl_lib_top


#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = axis_last_insert_tb
# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
TB_OBJECTS = $(addprefix $(WORKDIR), $(TARGET:=.o))

### Main target
$(TARGET): $(WORKDIR) $(DEPS) $(TB_OBJECTS)
	$(GHDL) -e $(GHDLFLAGS) $@

### To obtain object files
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
# create workdir	
$(WORKDIR):
	mkdir $@
	
# Make sure hdl lib is up to date
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR)
	
# To remove generated files
clean:
	rm -rf $(TARGET) $(WORKDIR)
	make -C $(HDL_LIB_TOP_DIR) clean	
