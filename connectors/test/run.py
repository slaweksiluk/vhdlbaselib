from itertools import product
from vunit import VUnit
from subprocess import call

# Make sure hdl lib is up to date
call(["make", "VHDL_STD=08"], cwd="../../")

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

vu.add_external_library("vhdlbaselib", "../../")

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("*.vhd")


vu.set_compile_option("ghdl.flags", ["--ieee=synopsys", "-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])

vu.main()
