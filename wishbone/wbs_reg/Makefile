GHDL=ghdl
WORK=vhdlbaselib
WORKDIR_NAME=work
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)/
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
DEPS=hdl_lib_top
HDL_LIB_TOP_DIR=../../
#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
# sources from CWD and additional from parent dir

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
#OBJECTS = wbs_reg_user_pkg.o
OBJECTS = $(addprefix $(WORKDIR), wbs_reg_user_pkg.o wbs_reg_pkg.o wbs_reg.o wbs_reg_wrap.o)
TARGET=wbs_reg_tb wrap_gen
TB_OBJ=$(WORKDIR)wbs_reg_tb.o $(WORKDIR)wrap_gen.o

#all: $(TARGET)
all: $(OBJECTS)

### Main target
# wokdir var afeter object is for creating work dir
$(TARGET): $(WORKDIR) $(DEPS) $(TB_OBJ)
#	$(CC) $(filter-out $(TARGET:=.o), $(OBJECTS)) $@.o -o $@
	$(GHDL) -e $(GHDLFLAGS) $@
#	$(GHDL) -i $(GHDLFLAGS) $(SOURCES)
#	$(GHDL) -m $(GHDLFLAGS) $@
	

### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	

#wrap_gen: wrap_gen.vhd
#	$(GHDL) -a $(GHDLFLAGS) wrap_gen.vhd	
#	$(GHDL) -e $(GHDLFLAGS) wrap_gen
#	./wrap_gen
		
# create workdir	
$(WORKDIR):
	mkdir $@
	
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR) WORKDIR=$(WORKDIR)	
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf

