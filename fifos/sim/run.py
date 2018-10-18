from itertools import product
from vunit import VUnit
from subprocess import call

# Make sure hdl lib is up to date
rc = call(["make", "VHDL_STD=08"], cwd="../../")
if rc != 0:
	quit()
# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

vu.add_external_library("vhdlbaselib", "../../")

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_file("axis_fifo_tb.vhd")
lib.add_source_file("axis_fifo_ate_tb.vhd")

vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

def gen_tests(obj, fwft):
    for fwft in fwft:
        config_name = "fwft=%s" % (fwft)
        obj.add_config(name=config_name,
                       generics=dict(
							fwft=fwft
                           ))

axis_fifo_ate_tb = lib.test_bench("axis_fifo_ate_tb")

for test in axis_fifo_ate_tb.get_tests():
	gen_tests(test, [False, True])

vu.main()
