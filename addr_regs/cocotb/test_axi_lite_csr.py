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
#    for i in range(1,30):
    yield axim.write(ADDRESS, DATA)
    yield Timer(CLK_PERIOD * 1)

    value = dut.slv_reg0;
    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Write 0x%08X to addres 0x%08X" % (value, ADDRESS))
    
#Write to address 0 and verify that value got through
@cocotb.test(skip = False)    
def rd_ro_addr_1(dut):
    """
    Description:
        Write to the register at address 0
        verify the value has changed

    Test ID: 1

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

    ADDRESS = 0x10
    DATA = 0xCD
    dut.ro_reg4 = DATA
    yield Timer(CLK_PERIOD * 2)
    value = yield axim.read(ADDRESS)
    yield Timer(CLK_PERIOD * 2)
    if value != DATA:
        #Fail
        raise TestFailure("Register at address 0x%08X should have been: \
                           0x%08X but was 0x%08X" % (ADDRESS, DATA, value))

    dut.log.info("Read 0x%08X from 0x%08X" % (value, ADDRESS))    
    
#Check all RW registers
@cocotb.test(skip = False)    
def rw_all(dut):
    """
    Description:
        Write, verif entiy out, read back addresses 0,4,8,12

    Test ID: 2

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

    ADDRESS = [0, 4, 8, 12]
    REGS = [dut.rw_reg0, dut.rw_reg1, dut.rw_reg2, dut.rw_reg3]
    for i, r in zip(ADDRESS, REGS):
        DATA = 0xab000000 + i
        yield axim.write(i, DATA)        
        yield Timer(CLK_PERIOD * 4)
        value = r;     
        if value != DATA:   
            #Fail
            raise TestFailure("Register out at address 0x%08X should have been: \
                               0x%08X but was 0x%08X" % (i, DATA, value))           
        value = yield axim.read(i)
        if value != DATA:   
            #Fail
            raise TestFailure("Register at address 0x%08X should have been: \
                               0x%08X but was 0x%08X" % (i, DATA, value))

        dut.log.info("Write 0x%08X to 0x%08X" % (value, i))        
        yield Timer(CLK_PERIOD * 4)
        
@cocotb.test(skip = False)    
def ro_all(dut):
    """
    Description:
        Set, read back read back addresses 16,20,24,28

    Test ID: 2

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

    ADDRESS = [16, 20, 24, 28]
    REGS = [dut.ro_reg4, dut.ro_reg5, dut.ro_reg6, dut.ro_reg7]
    for i, r in zip(ADDRESS, REGS):
        DATA = 0xefef0000 + i
        r <= DATA;     
        yield Timer(CLK_PERIOD * 4)
        value = yield axim.read(i)
        if value != DATA:   
            #Fail
            raise TestFailure("Register at address 0x%08X should have been: \
                               0x%08X but was 0x%08X" % (i, DATA, value))

        dut.log.info("Write 0x%08X to 0x%08X" % (value, i))        
        yield Timer(CLK_PERIOD * 4)        

