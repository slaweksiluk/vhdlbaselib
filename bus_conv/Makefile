GHDL=ghdl
WORK=vhdlbaselib
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# sources from CWD and additional from parent dir
SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
OBJECTS = $(addprefix $(WORKDIR), $(SOURCES:.vhd=.o))
# OBJECTS = $(addprefix $(WORKDIR), axis_ser.o)
all: $(OBJECTS)

### To obtain object files
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	

