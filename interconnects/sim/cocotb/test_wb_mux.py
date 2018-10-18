import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.result import TestSuccess
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.drivers.wishbone import WishboneMaster

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

_signals = ["cyc", "stb", "we", "sel", "adr", "datwr", "datrd", "ack"]

@cocotb.test()
def simple_wb_test(dut):
    for i in range(100):
        yield RisingEdge(dut.clk)    

