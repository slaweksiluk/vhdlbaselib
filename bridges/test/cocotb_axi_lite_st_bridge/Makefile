TOPLEVEL_LANG ?= vhdl
SIM = ghdl
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
#COCOTB=/home????
PYTHONPATH := ./model:$(PYTHONPATH)
SIM_ARGS = --wave=design.ghw

export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/hdl/

#DUT
VHDL_SOURCES = $(TOPDIR)/hdl/axi_lite_st_bridge.vhd

#Test Bench
#VHDL_SOURCES += $(TOPDIR)/hdl/tb_axi_lite_slave.v

TOPLEVEL = axi_lite_st_bridge

#GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_axi_lite_st_bridge

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim


