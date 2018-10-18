GHDL=ghdl
GHDLFLAGS=
MODULES=\
	full_adder.o \
	full_adder_tb


test: $(MODULES)
	./full_adder_tb --wave=full_adder_tb.ghw

# Binary depends on the object file
%: %.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Object file depends on source
%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

clean:
	echo "Cleaning up..."
	rm -f *.o
