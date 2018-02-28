PROJ_NAME=led_driver

$(PROJ_NAME).bin: $(PROJ_NAME).v $(PROJ_NAME).pcf
	yosys -q -p "synth_ice40 -blif $(PROJ_NAME).blif" $(PROJ_NAME).v
	arachne-pnr -d 8k -p $(PROJ_NAME).pcf $(PROJ_NAME).blif -o $(PROJ_NAME).txt
	#icebox_explain $(PROJ_NAME).txt > $(PROJ_NAME).ex
	icepack $(PROJ_NAME).txt $(PROJ_NAME).bin

$(PROJ_NAME)_tb.vcd: $(PROJ_NAME)_tb.v $(PROJ_NAME).v
	iverilog -o dsn $(PROJ_NAME)_tb.v $(PROJ_NAME).v
	vvp dsn

.PHONY: update_simulation
update_simulation: $(PROJ_NAME)_tb.vcd

.PHONY: run_simulation
run_simulation: $(PROJ_NAME)_tb.vcd
	gtkwave $(PROJ_NAME)_tb.vcd

.PHONY: flash_bitstream
flash_bitstream: $(PROJ_NAME).bin
	iceprog $(PROJ_NAME).bin

clean:
	rm -f $(PROJ_NAME).blif $(PROJ_NAME).txt $(PROJ_NAME).ex $(PROJ_NAME).bin
	rm -f dsn $(PROJ_NAME)_tb.vcd
