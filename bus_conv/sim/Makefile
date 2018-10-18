GHDL=ghdl
WORK=work
WORKDIR_NAME=work/
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)
HDL_LIB_TOP_DIR=../../
HDL_LIB_NAME=vhdlbaselib
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) -P$(HDL_LIB_TOP_DIR)$(HDL_LIB_NAME) --std=08 -frelaxed-rules
#GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) -P$(HDL_LIB_TOP_DIR)$(HDL_LIB_NAME)
DEPS=hdl_lib_top

#$@ Contains the target file name.
#$< Contains the first dependency file name.


# list of execs 
TARGET = axis_width_conv_tb

# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)
# Pbjects is sources with o
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
	
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR)
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf
	make -C $(HDL_LIB_TOP_DIR) clean

