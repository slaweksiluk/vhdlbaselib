TOPLEVEL_LANG ?= vhdl
SIM = ghdl
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
#COCOTB=/home/../../???
PYTHONPATH := ./model:$(PYTHONPATH)
SIM_ARGS = --wave=design.ghw

export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/

#DUT
VHDL_SOURCES = $(TOPDIR)/axi_lite_csr.vhd

#Test Bench
#VHDL_SOURCES += $(TOPDIR)/hdl/tb_axi_lite_slave.v

TOPLEVEL = axi_lite_csr

#GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_axi_lite_csr

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim


