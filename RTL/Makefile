# Target executable
TARGET = simv

# Source files
SRC = basic_func.sv add_cycle_7_area.v mult_cycle_5.v library.sv fakemem.sv

# VCS flags
VCSFLAGS = -sverilog -debug_all 
COMMON_FLAGS +=

# Simulator
SIM = vcs

# Altera FPGA library files (for simulation)
INC_V = /afs/ece/support/altera/release/16.1.2/quartus/eda/sim_lib/altera_primitives.v \
				/afs/ece/support/altera/release/16.1.2/quartus/eda/sim_lib/220model.v \
				/afs/ece/support/altera/release/16.1.2/quartus/eda/sim_lib/sgate.v \
				/afs/ece/support/altera/release/16.1.2/quartus/eda/sim_lib/altera_mf.v \
				/afs/ece/support/altera/release/16.1.2/quartus/eda/sim_lib/cyclonev_atoms.v
INC_V_FLAGS = $(addprefix -v , $(INC_V))
INC_SV =
INC_SV_FLAGS = $(addprefix -v , $(INC_SV))

# Copy common flags
VCSFLAGS += $(COMMON_FLAGS)

default : $(SRC)
	$(SIM) $(VCSFLAGS) $(INC_V_FLAGS) $(INC_SV_FLAGS) -o $(TARGET) $(SRC)

clean :
	-rm -rf csrc
	-rm -rf DVEfiles
	-rm $(TARGET)
	-rm -rf $(TARGET).daidir
	-rm ucli.key
	-rm -rf greybox_tmp
	-rm inter.vpd
	-rm .restartSimSession.tcl.old
