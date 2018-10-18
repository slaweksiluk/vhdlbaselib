from itertools import product
from vunit import VUnit
from subprocess import call

# Make sure hdl lib is up to date
call(["make", "VHDL_STD=08"], cwd="../../")

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

vu.add_external_library("vhdlbaselib", "../../vhdlbaselib/v08")

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_file("../axis_width_conv.vhd")
lib.add_source_file("axis_width_conv_tb.vhd")

vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])
#vu.set_sim_option("ghdl.sim_flags", ["--wave=axis_width_conv_tb.ghw"])

#
# Stuff for multi generic tests
#
tb_generated = lib.entity("axis_width_conv_tb")
# Just set a generic for all configurations within the test bench
#tb_generated.set_generic("message", "set-for-entity")

def generate_tests(obj, use_keep, slave_width, master_width, rand_stim, slave_test_len):
    """
    Generate test by varying the data_width and sign generics
    """

    for use_keep, slave_width, master_width, rand_stim, slave_test_len in product(use_keep, slave_width, master_width, rand_stim, slave_test_len):
        # This configuration name is added as a suffix to the test bench name
        config_name = "slave_width=%i,master_width=%i,use_keep=%s,rand_stim=%s,slave_test_len=%i" % (slave_width, master_width, use_keep, rand_stim, slave_test_len)

        # Add the configuration with a post check function to verify the output
        obj.add_config(name=config_name,
                       generics=dict(
                           slave_width=slave_width,
                           master_width=master_width,
                           use_keep=use_keep,
                           rand_stim=rand_stim,
                           slave_test_len=slave_test_len
                           ))
                       
for test in tb_generated.get_tests():
    if test.name == "Test1":
        generate_tests(test, [False], [32], [8], [False, True], [64])
        generate_tests(test, [False], [16], [4], [False, True], [64])
        #generate_tests(test, [False], [8], [2], [False])   # not supp 
        generate_tests(test, [False], [32], [16], [False, True], [64])
        generate_tests(test, [False], [30], [6], [False, True], [64])
        generate_tests(test, [False], [15], [3], [False, True], [64, 1])
    elif test.name == "Test2":
        generate_tests(test, [True], [32], [8], [False, True], [64])
        generate_tests(test, [True], [16], [4], [False, True], [64])
        generate_tests(test, [True], [32], [16], [False, True], [64])
        generate_tests(test, [True], [30], [6], [False, True], [64])
        generate_tests(test, [True], [15], [3], [False, True], [64])    
    

# Run vunit function
vu.main()
