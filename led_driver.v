/*
 * This file is part of LEDMatrixDriver.
 * Copyright 2018 Mario Gomez <mario.gomez@teubi.co>
 *
 * LEDMatrixDriver is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * LEDMatrixDriver is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with LEDMatrixDriver.  If not, see <http://www.gnu.org/licenses/>.
*/
module led_driver( // BEGIN: led_driver
  input  CLK_I,   // Clock from FPGA
  output R0,      // Serial data out for red LEDs in top bank
  output G0,      // Serial data out for green LEDs in top bank
  output B0,      // Serial data out for blue LEDs in top bank
  output R1,      // Serial data out for red LEDs in bottom bank
  output G1,      // Serial data out for green LEDs in bottom bank
  output B1,      // Serial data out for blue LEDs in bottom bank
  output RA,      // Demux address line out (LSB)
  output RB,      // Demux address line out
  output RC,      // Demux address line out
  output RD,      // Demux address line out (MSB)
  output CLK_O,   // Clock output
  output LATCH,   // Latch signal
  output OE,      // Output Enable (OE)
  output LED1,    // Debug LEDs (Shares signal with RA)
  output LED2,    // Debug LEDs (Shares signal with RB)
  output LED3,    // Debug LEDs (Shares signal with RC)
  output LED4,    // Debug LEDs (Shares signal with RD)
  output LED5,    // Debug LEDs (Shares signal with Latch)
  output LED6,    // Debug LEDs (Shares signal with OE)
  output LED7,    // Debug LEDs (Shared signal with CLK_I)
  output LED8     // Debug LEDs (Shared signal with CLK_O)
);
  parameter BASE_FREQ = 12000000; // Base clock frequency
  parameter TARGET_FREQ = 300000; // Output target frequency (Must be BASE_FREQ/2 at max)
  parameter OVERSCAN_STEP = 16; // Overscan step size
  parameter BLACK_CUTOFF = 13; // Black cutoff point

  reg [23:0] frame_buffer[0:1023]; // Frame buffer stores the 24-bit color info

  reg [8:0] pixel_pos; // Current pixel position in the frame buffer

  // This records are needed because the frame buffer memory
  // is not directly accesible.
  reg [23:0] color_bank0; // Register to store current pixel color for bank 1
  reg [23:0] color_bank1; // Register to store current pixel color for bank 2

  // overscan_value stores the current elapsed time within frame
  // the current pixel value is compared against the accumulated
  // time to determine if it should be on or off.
  reg [7:0]  overscan_value;

  // cycle_counter is used to divide the input clock
  reg [32:0] cycle_counter;
  // prescaler is pre-calculated to determine cycle length
  reg [32:0] prescaler;

  // output color registers mapped to the color data lines
  reg red0, red1; // Red color registers
  reg green0, green1; // Green color registers
  reg blue0, blue1; // Blue color registers

  // We need two records to store the row because the
  // framebuffer color info is read on the second cycle
  // this means that the current row from the pixel address
  // is always one address forward.
  reg [3:0] current_row; // Current accesed row (top/bottom) banks
  reg [3:0] current_row_delayed; // Actual selected row

  reg [6:0] current_bit; // In-row bit counter, used to determine state changes.
  reg latch_signal,oe_signal; // Registers for LED Panel control signals

  reg ctrl_clk; // Internal control clock
  reg out_clk_en; // Output clock control
  reg out_clk; // Output clock signal

  reg ready; // Used just to guarantee that the state machine starts with known values

  reg [1:0] current_state; // Current machine state

  initial begin
    // Pixel pattern is generated using a Python script.
    $readmemh("led_pattern.list", frame_buffer);

    ready = 1'b0;

    // Initial pixel address in the framebuffer
    pixel_pos = 9'h000;

    // Internal memory pointers
    current_row = 0;
    current_bit = 0;
    current_row_delayed = 0;

    // Clock generation and control
    cycle_counter = 0;
    out_clk_en = 0;
    ctrl_clk = 0;

    // Number of cycles needed to generate the internal clock
    prescaler = TARGET_FREQ/(BASE_FREQ*2);

    // Internal machine states
    current_state = 0;

    // Latch control signals
    oe_signal = 1;
    latch_signal = 0;

    // Color info related data.
    color_bank0 = 0;
    color_bank1 = 0;
    red0 = 0;
    green0 = 0;
    blue0 = 0;
    red1 = 0;
    green1 = 0;
    blue1 = 0;
    overscan_value = 0;
  end

  // Combinational logic to disable the output clock
  always @(ctrl_clk, out_clk_en)
  begin
    out_clk = ctrl_clk & out_clk_en;
  end

  // The state machine reacts to positive edges on the input clock line
  always @(posedge CLK_I)
  begin
    cycle_counter <= cycle_counter + 1;

    // Internal clock generation
    if (cycle_counter==prescaler)
    begin
      ctrl_clk <= ~ctrl_clk;
      cycle_counter <= 0;

      // Internal clock edge detection (Equiv. @posedge over ctrl_clk)
      if (ctrl_clk)
      begin

        // State machine:
        // 0: Pushing data
        if (current_state == 0)
        begin
          cycle_counter <= 0;

          pixel_pos <= pixel_pos + 1;
          if(ready)
          begin
            current_bit <= current_bit + 1;
          end

          // Color data is extracted from the frame buffer memory using simple arithmetics.
          // Row and bank position are calculated also from the pixel address.
          // Once all the color info is sent we send the Latch/OE signals and repeat.

          // Reading color info from the frame buffer
          current_row_delayed <= pixel_pos[8:5]-1;
          color_bank0 <= frame_buffer[{1'b0,pixel_pos}]; // Reads pixel from top bank
          color_bank1 <= frame_buffer[{1'b1,pixel_pos}]; // Reads pixel from bottom bank

          // Overscan calculation for top bank pixel
          red0 <= (color_bank0[7:0] > BLACK_CUTOFF && color_bank0[7:0] > overscan_value);
          green0 <= (color_bank0[15:8] > BLACK_CUTOFF && color_bank0[15:8] > overscan_value);
          blue0 <= (color_bank0[23:16] > BLACK_CUTOFF && color_bank0[23:16] > overscan_value);

          // Overscan calculation for bottom bank pixel
          red1 <= (color_bank1[7:0] > BLACK_CUTOFF && color_bank1[7:0] > overscan_value);
          green1 <= (color_bank1[15:8] > BLACK_CUTOFF && color_bank1[15:8] > overscan_value);
          blue1 <= (color_bank1[23:16] > BLACK_CUTOFF && color_bank1[23:16] > overscan_value);

          // Following Ifs control the end of the data transfer cycle
          if(pixel_pos==1)
          begin
            ready<=1;
            out_clk_en <= 1;
          end
          if (current_bit==31)
          begin
            current_state <= 1;
            oe_signal <= 0;
            out_clk_en <= 0;
            current_row <= current_row_delayed;
          end
          else
          begin
            oe_signal <= 1;
          end
        end
        // State machine:
        // 1: Sending Latch & OE Pulse
        if (current_state == 1)
        begin
          latch_signal <= 0;
          current_bit <= 0;
          current_state <= 0;
          out_clk_en <= 1;
        end
      end
      else // Internal clock edge detection (Equiv. @negedge over ctrl_clk)
      begin
        // Make sure that we are in the last row before incrementing
        // the overscan_value
        if (current_state == 0 && current_bit==31 & current_row[3:0]==4'hF)
        begin
          overscan_value <= overscan_value+OVERSCAN_STEP;
        end

        if (current_state == 1)
        begin
          latch_signal <= 1;
          current_bit <= 0;
        end
      end
    end
  end

   // Assign clock input/output
   assign CLK_O = out_clk;
   assign LED7 = out_clk;
   assign LED8 = CLK_I;

   // Assing demux address lines
   assign RA = current_row[0];
   assign LED1 = current_row[0];
   assign RB = current_row[1];
   assign LED2 = current_row[1];
   assign RC = current_row[2];
   assign LED3 = current_row[2];
   assign RD = current_row[3];
   assign LED4 = current_row[3];

   // Assign color info lines
   assign R0 = red0;
   assign G0 = green0;
   assign B0 = blue0;
   assign R1 = red1;
   assign G1 = green1;
   assign B1 = blue1;

   // Assign control signals
   assign LATCH = latch_signal;
   assign LED5 = latch_signal;
   assign OE = ~oe_signal;
   assign LED6 = ~oe_signal;
endmodule // END: led_driver
