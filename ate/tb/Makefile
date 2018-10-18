GHDL=ghdl
WORK=work
WORKDIR_NAME=work
WORKDIR=$(shell pwd)/$(WORKDIR_NAME)
HDL_LIB_TOP_DIR=../../
GHDLFLAGS=--work=$(WORK) --ieee=synopsys --workdir=$(WORKDIR) -P$(HDL_LIB_TOP_DIR)
DEPS=hdl_lib_top

#DEPS=hdl_lib_conn
#CONN_DIR=../connectors
#GHDLFLAGS=--work=$(WORK) -P../connectors --ieee=synopsys

#$@ Contains the target file name.
#$< Contains the first dependency file name.

# list of execs 
TARGET = axis_test_env_tb ate_example_tb
# sources from CWD and additional from parent dir
#SOURCES = $(wildcard *.vhd)

# Pbjects is sources with o
#OBJECTS = $(SOURCES:.vhd=.o)
TB_OBJECTS = $(addprefix $(WORKDIR), ate_example_tb.o axis_test_env_tb.o)

#all: $(TARGET)
#all: $(WORKDIR) $(OBJECTS)


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
	make -C $(HDL_LIB_TOP_DIR)
		
# To remove generated files
clean:
	rm -rf $(WORKDIR) $(OBJECTS) $(TARGET) *.cf
	make -C $(HDL_LIB_TOP_DIR) clean

