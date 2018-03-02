# This file is part of LEDMatrixDriver.
# Copyright 2018 Mario Gomez <mario.gomez@teubi.co>
#
# LEDMatrixDriver is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# LEDMatrixDriver is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LEDMatrixDriver.  If not, see <http://www.gnu.org/licenses/>.

PROJ_NAME=led_driver

$(PROJ_NAME).bin: $(PROJ_NAME).v $(PROJ_NAME).pcf
	yosys -q -p "synth_ice40 -blif $(PROJ_NAME).blif" $(PROJ_NAME).v
	arachne-pnr -d 8k -p $(PROJ_NAME).pcf $(PROJ_NAME).blif -o $(PROJ_NAME).txt
	icepack $(PROJ_NAME).txt $(PROJ_NAME).bin

$(PROJ_NAME)_tb.vcd: $(PROJ_NAME)_tb.v $(PROJ_NAME).v
	iverilog -o dsn $(PROJ_NAME)_tb.v $(PROJ_NAME).v
	vvp dsn

explain: $(PROJ_NAME).bin
	icebox_explain $(PROJ_NAME).txt > $(PROJ_NAME).ex

.PHONY: update_bitmap
update_bitmap: nyancat.png
	python process_image.py > led_pattern.list

.PHONY: update_simulation
update_simulation: $(PROJ_NAME)_tb.vcd led_pattern.list

.PHONY: run_simulation
run_simulation: $(PROJ_NAME)_tb.vcd
	gtkwave $(PROJ_NAME)_tb.vcd

.PHONY: flash_bitstream
flash_bitstream: $(PROJ_NAME).bin
	iceprog $(PROJ_NAME).bin

clean:
	rm -f $(PROJ_NAME).blif $(PROJ_NAME).txt $(PROJ_NAME).ex $(PROJ_NAME).bin
	rm -f dsn $(PROJ_NAME)_tb.vcd
