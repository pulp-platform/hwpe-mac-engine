.PHONY: build lib clean 

mkfile_path := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

sim:
	vsim -lib work vopt_mac_top_wrap  +notimingchecks
sim-nogui:
	vsim -batch -lib work vopt_mac_top_wrap -do $(mkfile_path)/vsimulate/rtl_sim.tcl -logfile transcript

opt:
	$(mkfile_path)/vsimulate/rtl_vopt.tcl

build:
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk build
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk build

lib:
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk lib
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk lib
	vlib work
	vmap work work

clean:
	@make --no-print-directory -f $(mkfile_path)/vcompile/ips.mk clean
	@make --no-print-directory -f $(mkfile_path)/vcompile/rtl.mk clean
	rm -rf work

