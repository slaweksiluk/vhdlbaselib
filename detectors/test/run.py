from itertools import product
from vunit import VUnit
from subprocess import call

# Make sure hdl lib is up to date
rc = call(["make", "VHDL_STD=08"], cwd="../../")
if rc != 0:
	print "library build fail, exit..."
	quit()

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

vu.add_external_library("vhdlbaselib", "../../")
vu.add_osvvm()
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("*.vhd")

vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

def encode(tb_cfg):
    return ",".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

def gen_tests(obj, *args):
    for max_pending, req_prob, ack_prob in product(*args):
        tb_cfg = dict(
                max_pending=max_pending,
                req_prob=req_prob,
                ack_prob=ack_prob,
                )
        config_name = encode(tb_cfg)
        obj.add_config(name=config_name,
                       generics=dict(encoded_tb_cfg=encode(tb_cfg)))

wb_cycle_end_det_tb = lib.test_bench("wb_cycle_end_det_tb")

# Just set a generic for all configurations within the test bench
wb_cycle_end_det_tb.set_generic("encoded_tb_cfg", encode(dict(
                max_pending=4,
                req_prob=1.0,
                ack_prob=1.0,
                )))

for test in wb_cycle_end_det_tb.get_tests():
	if test.name == "random":
	    gen_tests(test, [1, 4, 8], [0.5, 1.0, 0.7, 0.9, 0.6], [0.5, 1.0, 0.8, 0.2, 0.7])


vu.main()
