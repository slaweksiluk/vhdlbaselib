from itertools import product
from vunit import VUnit
from subprocess import call

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

def gen_tests(obj, *args):
    for data_width, addr_width, num_desc, max_trans, ack_prob, stall_prob, buf_rd_prob \
    in product(*args):
        tb_cfg = dict(
                data_width=data_width,
                addr_width=addr_width,
                num_desc=num_desc,
                max_trans=max_trans,
                ack_prob=ack_prob,
                stall_prob=stall_prob,
				buf_rd_prob=buf_rd_prob
                )
        config_name = encode(tb_cfg)
        obj.add_config(name=config_name,
                       generics=dict(encoded_tb_cfg=encode(tb_cfg)))

wb_master_axis_master_bridge_tb = lib.test_bench("wb_master_axis_master_bridge_tb")

for test in wb_master_axis_master_bridge_tb.get_tests():
	if test.name == "variable-desc-length":
	    gen_tests(test, [8], [32], [1,15], [1,15], [1.0, 0.3], [0.0, 0.7], [0.1, 1.0])
	elif test.name == "single-length-two":
	    gen_tests(test, [8], [32], [1], [2], [1.0], [0.0], [0.5])
	else:
	    gen_tests(test, [8], [32], [1], [1], [1.0], [0.0], [0.5])

wb_master_axis_slave_bridge_tb = lib.test_bench("wb_master_axis_slave_bridge_tb")

for test in wb_master_axis_slave_bridge_tb.get_tests():
	# Last param buf_rd_prob not used in slave
	if test.name == "single-length-two":
	    gen_tests(test, [8], [32], [1], [2], [1.0], [0.0], [0.5])
	elif test.name == "variable-desc-length":
	    gen_tests(test, [8, 128], [32, 64], [1,128], [1,3], [1.0, 0.4], [0.0, 0.8], [0.0])
	else:
	    gen_tests(test, [8], [32], [1], [1], [1.0], [0.0], [0.5])

vu.main()
