GHDL=ghdl
WORK=vhdlbaselib
WORKDIR_NAME=work
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)
DEPS=hdl_lib_top
HDL_LIB_TOP_DIR=../

#DEPS=hdl_lib_conn
#CONN_DIR=../connectors
#GHDLFLAGS=--work=$(WORK) -P../connectors --ieee=synopsys
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR)

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = axis_test_env_tb ate_example_tb
# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
OBJECTS = $(addprefix $(WORKDIR), txt_util.o common_pkg.o axis_pkg.o wb_test_env_pkg.o)
#TB_OBJECTS = $(addprefix $(WORKDIR), axis_test_env_tb.o ate_example_tb.o)

#all: $(TARGET)
all: $(WORKDIR) $(OBJECTS)


### Main target
$(TARGET): $(WORKDIR) $(DEPS) $(TB_OBJECTS)
	$(GHDL) -e $(GHDLFLAGS) $@
	

### To obtain object files
#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)
$(WORKDIR)%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<	
	
# create workdir	
$(WORKDIR):
	mkdir $@
	
hdl_lib_top:
	make -C $(HDL_LIB_TOP_DIR) WORKDIR=$(WORKDIR)
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf

