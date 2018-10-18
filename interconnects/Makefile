GHDL ?= ghdl
#WORK ?= vhdlbaselib
#VHDL_STD ?= 93
#WORKDIR ?= $(shell pwd)/$(WORK)/v$(VHDL_STD)/
#GHDLFLAGS ?= --work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) --std=$(VHDL_STD)

#$@ Contains the target file name.
#$< Contains the first dependency file name.


# sources from CWD and additional from parent dir
SOURCES = $(wildcard *.vhd)
#SOURCES = wishbone_pkg.vhd wb_mux.vhd

# Pbjects is sources with o
OBJECTS = $(addprefix $(WORKDIR), $(SOURCES:.vhd=.o))
#OBJECTS = $(addprefix $(WORKDIR), axis_test_env_pkg.o)
all: $(WORKDIR) $(OBJECTS)

### Main target
#$(TARGET): $(WORKDIR) $(DEPS) $(OBJECTS)
#	$(CC) $(filter-out $(TARGET:=.o), $(OBJECTS)) $@.o -o $@
#	$(GHDL) -e $(GHDLFLAGS) $@

### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
# create workdir	
#$(WORKDIR):
#	mkdir $@
	
# To remove generated files
#clean:
#	#make -C $(PKG_DIR) clean WORKDIR=$(PKG_WORK_DIR)
#	rm -rf $(TARGET) $(OBJECTS) $(WORKDIR) *.cf

