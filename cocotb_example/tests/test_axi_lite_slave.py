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

    yield axim.write(ADDRESS, DATA)
    yield Timer(CLK_PERIOD * 10)

    value = dut.slv_reg0;
    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Write 0x%08X to addres 0x%08X" % (value, ADDRESS))


#Read back a value at address 0x01
@cocotb.test(skip = False)
def read_address_1(dut):
    """
    Description
        Use cocotb to set the value of the register at address 0x01
        Use AXIML to read the contents of that register and
        compare the values

    Test ID: 1

    Expected Results:
        The value read from the register is the same as the value written
    """
    #Reset
    dut.S_AXI_ARESETN <=  0
    #dut.test_id <= 0
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.S_AXI_ARESETN <= 1

    ADDRESS = 0x01
    DATA = 0xCD

#    dut.slv_reg0 <= DATA
    dut.slv_reg1 <= DATA
#    dut.slv_reg2 <= DATA
#    dut.slv_reg3 <= DATA
    yield Timer(CLK_PERIOD * 10)

    value = yield axim.read(ADDRESS)
    yield Timer(CLK_PERIOD * 10)

    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Read: 0x%08X From Address: 0x%08X" % (value, ADDRESS))



@cocotb.test(skip = False)
def write_and_read(dut):
    """
    Description:
        Write to the register at address 0
        read back from that register and verify the value is the same

    Test ID: 2

    Expected Results:
        The contents of the register is the same as the value written
    """

    #Reset
    dut.S_AXI_ARESETN <=  0
    #dut.test_id <= 2
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.S_AXI_ARESETN <= 1

    ADDRESS = 0x03
    DATA = 0xEB

    #Write to the register
    yield axim.write(ADDRESS, DATA)
    yield Timer(CLK_PERIOD * 10)

    #Read back the value
    value = yield axim.read(ADDRESS)
    yield Timer(CLK_PERIOD * 10)

    #value = dut.slv_reg0
    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Write 0x%08X to addres 0x%08X" % (value, ADDRESS))

@cocotb.test(skip = False, expect_error=True)
def write_fail(dut):
    """
    Description:
        Attemp to write data to an address that doesn't exist. This test
        should fail

    Test ID: 3

    Expected Results:
        The AXIML bus should throw an exception because the user attempted
        to write to an invalid address
    """
    #Reset
    dut.S_AXI_ARESETN <=  0
    #dut.test_id <= 3
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.S_AXI_ARESETN <= 1

    ADDRESS = 0x02
    DATA = 0xAB

    try:
        yield axim.write(ADDRESS, DATA)
        yield Timer(CLK_PERIOD * 10)
    except AXIProtocolError as e:
        print "Exception: %s" % str(e)
        dut.log.info("Bus Successfully Raised an Error")
        raise TestSuccess()
    raise TestFailure("AXI Bus Should have raised an ERROR when writing to \
                        the wrong bus")

@cocotb.test(skip = False, expect_error=True)
def read_fail(dut):
    """
    Description:
        Attemp to write data to an address that doesn't exist. This test
        should fail

    Test ID: 4

    Expected Results:
        The AXIML bus should throw an exception because the user attempted
        to write to an invalid address
    """
    #Reset
    dut.S_AXI_ARESETN <=  0
    #dut.test_id <= 4
    axim = AXI4LiteMaster(dut, "S_AXI", dut.S_AXI_ACLK)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.S_AXI_ARESETN <= 1

    ADDRESS = 0x03
    DATA = 0xAB

    try:
        yield axim.read(ADDRESS, DATA)
        yield Timer(CLK_PERIOD * 10)
    except AXIProtocolError as e:
        print "Exception: %s" % str(e)
        dut.log.info("Bus Successfully Raised an Error")
        raise TestSuccess()
    raise TestFailure("AXI Bus Should have raised an ERROR when writing to \
                        the wrong bus")


