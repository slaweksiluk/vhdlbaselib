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
lib = vu.add_library("lib")
lib.add_source_files("*.vhd")

vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

vu.main()
