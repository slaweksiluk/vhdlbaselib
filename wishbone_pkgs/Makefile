#$@ Contains the target file name.
#$< Contains the first dependency file name.

#SOURCES = $(wildcard *.vhd)
# Chose sources depnding on the vhdl std selected
ifeq ($(VHDL_STD), 93)
	SOURCES = wishbone_pkg.vhd
endif

ifeq ($(VHDL_STD), 08)
	SOURCES = wishbone_pkg-2008.vhd wishbone_array_pkg-2008.vhd
endif

# Pbjects is sources with o
OBJECTS = $(addprefix $(WORKDIR), $(SOURCES:.vhd=.o))
#OBJECTS = $(addprefix $(WORKDIR), axis_test_env_pkg.o)
all: $(OBJECTS)

### Main target
#$(TARGET): $(WORKDIR) $(DEPS) $(OBJECTS)
#	$(GHDL) -e $(GHDLFLAGS) $@

### To obtain object files
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
clean:
	rm -rf $(OBJECTS) *.cf
