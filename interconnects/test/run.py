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
vu.add_verification_components()
# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("*.vhd")


vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

def encode(tb_cfg):
    return ",".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])


def gen_wb_tests(obj, *args):
    for num_slaves, data_width, addr_width, num_trans, ack_prob, stall_prob \
    in product(*args):
        tb_cfg = dict(
                num_slaves=num_slaves,
                data_width=data_width,
                addr_width=addr_width,
                ack_prob=ack_prob,
                stall_prob=stall_prob,
                num_trans=num_trans
                )
        config_name = encode(tb_cfg)
        obj.add_config(name=config_name, generics=dict(encoded_tb_cfg=encode(tb_cfg)))


wb_demux_tb = lib.test_bench("wb_demux_tb")

for test in wb_demux_tb.get_tests():
	gen_wb_tests(test, [1,3], [32], [32], [1,16], [1.0, 0.3], [0.0, 0.7])


vu.main()
