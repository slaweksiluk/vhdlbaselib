GHDL ?= ghdl
SOURCES = $(wildcard *.vhd)
OBJECTS = $(addprefix $(WORKDIR), $(SOURCES:.vhd=.o))

all: $(OBJECTS)

$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<
