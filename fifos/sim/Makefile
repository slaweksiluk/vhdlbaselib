GHDL=ghdl
WORK=work
WORKDIR=$(shell pwd)/$(WORK)
HDL_LIB_TOP_DIR=../../
GHDLFLAGS=--work=$(WORK) --workdir=$(WORKDIR) --std=08 -P$(HDL_LIB_TOP_DIR)\
--ieee=synopsys -frelaxed-rules
DEPS=hdl_lib_top

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs
TARGET = axis_fifo_ate_tb

# Object is target with .o suffix
# TB_OBJECTS = $(addprefix $(WORKDIR), $(TARGET:=.o))

### Main target
$(TARGET): $(WORKDIR) $(DEPS)
	$(GHDL) -a $(GHDLFLAGS) $@.vhd
	$(GHDL) -e $(GHDLFLAGS) $@

### To obtain object files
#$(WORKDIR)%.o: %.vhd
#	$(GHDL) -a $(GHDLFLAGS) $<

# create workdir
$(WORKDIR):
	mkdir $@

hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR) VHDL_STD=08

# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf
	make -C $(HDL_LIB_TOP_DIR) clean

