TOPLEVEL_LANG ?= vhdl
SIM = ghdl
PWD=$(shell pwd)
TOPDIR=$(PWD)/../..
COCOTB=$(shell cd ~ && pwd)/git/github/cocotb
PYTHONPATH := ./model:$(PYTHONPATH)
SIM_ARGS = --wave=design.ghw

export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/

#DUT
#VHDL_SOURCES = $(TOPDIR)/wishbone_pkg.vhd 
VHDL_SOURCES += $(TOPDIR)/wb_mux.vhd

#Test Bench
#VHDL_SOURCES += $(TOPDIR)/hdl/tb_axi_lite_slave.v

TOPLEVEL = wb_mux

#GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_wb_mux

#export GHDL_ARGS = -P/.../..???
#export RTL_LIBRARY = vhdlbaselib


include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim


