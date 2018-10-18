GHDL=ghdl
WORK=vhdlbaselib
WORKDIR_NAME=work
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
# sources from CWD and additional from parent dir

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
#OBJECTS = wb_switch_pkg.o
OBJECTS = $(addprefix $(WORKDIR), wb_switch_pkg.o wb_switch.o wbs_mem.o)

#all: $(TARGET)
all: $(OBJECTS)

### Main target
# wokdir var afeter object is for creating work dir
$(TARGET): $(WORKDIR) $(OBJECTS)
#	$(CC) $(filter-out $(TARGET:=.o), $(OBJECTS)) $@.o -o $@
	$(GHDL) -e $(GHDLFLAGS) $@
#	$(GHDL) -i $(GHDLFLAGS) $(SOURCES)
#	$(GHDL) -m $(GHDLFLAGS) $@
	

### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
# create workdir	
$(WORKDIR):
	mkdir $@
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf

