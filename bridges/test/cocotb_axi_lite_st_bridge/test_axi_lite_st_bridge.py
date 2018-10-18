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
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXIProtocolError

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    cocotb.fork(Clock(dut.S_AXI_ACLK, CLK_PERIOD).start())

#Write to address 0 and verify that value got through
@cocotb.test(skip = False)
def write_address_0(dut):
    """
    Description:
        Write to the register at address 0
        verify the value has changed

    Test ID: 0

    Expected Results:
        The value read directly from the register is the same as the
        value written
    """

    #Reset
    dut.S_AXI_ARESETN <=  0
    #dut.test_id <= 0
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.S_AXI_ARESETN <= 1

    ADDRESS = 0x00
    DATA = 0xAB
    for i in range(1,30):
        yield axim.write(ADDRESS, DATA)
        yield Timer(CLK_PERIOD * 10)

    value = dut.slv_reg0;
    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Write 0x%08X to addres 0x%08X" % (value, ADDRESS))

