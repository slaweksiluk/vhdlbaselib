GHDL=ghdl
WORK=vhdlbaselib
WORKDIR_NAME=work
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
DEPS=hdl_lib_top
HDL_LIB_TOP_DIR=../

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = prbs_gen_tb

# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
# OBJECTS = $(SOURCES:.vhd=.o)
OBJECTS = $(addprefix $(WORKDIR), prbs_gen.o)
TB_OBJECTS = $(addprefix $(WORKDIR), prbs_gen_tb.o)
all: $(OBJECTS)

### Main target
$(TARGET): $(WORKDIR) $(DEPS) $(TB_OBJECTS)
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
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR) WORKDIR=$(WORKDIR)
	
# To remove generated files
clean:
	#make -C $(PKG_DIR) clean WORKDIR=$(PKG_WORK_DIR)
	rm -rf $(TARGET) $(OBJECTS) $(WORKDIR) *.cf

