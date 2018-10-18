GHDL=ghdl
WORK=work
WORKDIR=$(shell pwd)/$(WORK)
HDL_LIB_TOP_DIR=../../
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) -P$(HDL_LIB_TOP_DIR)
DEPS=hdl_lib_top

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = wb_mux_tb
# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
#TB_OBJECTS = $(addprefix $(WORKDIR), ate_example_tb.o axis_test_env_tb.o)

#all: $(TARGET)
#all: $(WORKDIR) $(OBJECTS)


### Main target
$(TARGET): $(WORKDIR) $(DEPS)
	$(GHDL) -a $(GHDLFLAGS) $@.vhd
	$(GHDL) -e $(GHDLFLAGS) $@
	
# create workdir	
$(WORKDIR):
	mkdir $@
	
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR)
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf
