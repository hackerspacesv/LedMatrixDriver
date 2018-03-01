
module led_driver(
  input  CLK_I,   // Clock from FPGA
  output R0,      // Serial data for red LEDs in top bank
  output G0,      // Serial data for green LEDs in top bank
  output B0,      // Serial data for blue LEDs in top bank
  output R1,      // Serial data for red LEDs in bottom bank
  output G1,      // Serial data for green LEDs in bottom bank
  output B1,      // Serial data for blue LEDs in bottom bank
  output RA,      // Demux address line (LSB)
  output RB,      // Demux address line
  output RC,      // Demux address line
  output RD,      // Demux address line (MSB)
  output CLK_O,   // Clock output
  output LATCH,   // Latch signal
  output OE,      // Output enable
  output LED1,    // Debug LEDs
  output LED2,    // Debug LEDs
  output LED3,    // Debug LEDs
  output LED4,    // Debug LEDs
  output LED5,
  output LED6,
  output LED7,
  output LED8
);
  parameter BASE_FREQ = 12000000;
  parameter TARGET_FREQ = 300000;
  parameter OVERSCAN_STEP = 64;
  parameter BLACK_CUTOFF = 62;

  reg [23:0] frame_buffer[0:1023];
  reg [8:0] pixel_pos;
  reg [23:0] color_bank0;
  reg [23:0] color_bank1;
  
  reg [7:0]  overscan_value;

  reg [32:0] cycle_counter;
  reg [32:0] prescaler;
  reg red0, red1; // Red color registers
  reg green0, green1; // Green color registers
  reg blue0, blue1; // Blue color registers

  reg [3:0] current_row; // Current row (top/bottom) banks
  reg [3:0] current_row_delayed;
  reg [6:0] current_bit; // Current bit
  reg [6:0] out_bit; // Current bit
  reg inc_row,latch_signal,oe_signal; // Internal signal registers
  reg oe_output, latch_output;

  reg out_clk; // Output clock
  reg out_clk_en; // Output clock control
  reg out_clk_o;

  reg ready;

  reg [1:0] current_state;

  initial begin
    // Load pattern from file
    $readmemh("led_pattern.list", frame_buffer);

    pixel_pos = 9'h000;

    prescaler = TARGET_FREQ/(BASE_FREQ*2);

    cycle_counter = 0;
    out_clk_en = 0;
    out_clk = 0;
    
    current_state = 0;
    
    current_row = 0;
    current_bit = 0;
    current_row_delayed = 0;
    
    oe_signal = 1;
    latch_signal = 0;
    
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

  // Enable/disable the output clock
  always @(out_clk, out_clk_en)
  begin
    out_clk_o = out_clk & out_clk_en;
  end

  always @(posedge CLK_I)
  begin


    // Internal clock generation
    if (cycle_counter==prescaler)
    begin
      out_clk <= ~out_clk;
      cycle_counter <= cycle_counter + 1;
      
      // Edge detection (equiv @posedge over out_clk)
      if (out_clk)
      begin
        // State machine:
        // 0: Running clock
        if (current_state == 0)
        begin
        
          pixel_pos <= pixel_pos + 1;
          if(ready)
          begin
            current_bit <= current_bit + 1;
          end

          current_row_delayed <= pixel_pos[8:5]-1;
          color_bank0 <= frame_buffer[{1'b0,pixel_pos}];
          color_bank1 <= frame_buffer[{1'b1,pixel_pos}];

          red0 <= (color_bank0[7:0] > BLACK_CUTOFF && color_bank0[7:0] > overscan_value);
          green0 <= (color_bank0[15:8] > BLACK_CUTOFF && color_bank0[15:8] > overscan_value);
          blue0 <= (color_bank0[23:16] > BLACK_CUTOFF && color_bank0[23:16] > overscan_value);

          red1 <= (color_bank1[7:0] > BLACK_CUTOFF && color_bank1[7:0] > overscan_value);
          green1 <= (color_bank1[15:8] > BLACK_CUTOFF && color_bank1[15:8] > overscan_value);
          blue1 <= (color_bank1[23:16] > BLACK_CUTOFF && color_bank1[23:16] > overscan_value);

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
        if (current_state == 1)
        begin
          latch_signal <= 0;
          current_bit <= 0;
          out_bit <= 0;
          current_state <= 0;
          out_clk_en <= 1;
        end
      end
      else // Equiv (@negedge)
      begin
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
      cycle_counter <= 0;
    end
  end
/*
  // External clock divider
  always @(negedge CLK_I)
  begin
    cicle_counter <= cicle_counter + 1;

    // Internal clock generation
    if (cicle_counter==prescaler)
    begin

      out_clk <= ~out_clk;

      // State machine:
      // 0: Running clock
      if (current_state == 0)
      begin
        if(out_clk)
        begin
          current_bit <= current_bit + 1;
          if (out_bit < 31)
          begin
            out_bit <= out_bit + 1;
            oe_signal <= 1;
          end
          else
          begin
            out_bit <= 0;
          end
        end
        else
        begin
          if (current_bit >= 31)
          begin
            oe_signal <= 0;
          end
          if (current_bit == 32)
          begin
            out_clk_en <= 0;
            current_state <= 1;
            latch_signal <= 1;
            current_row <= current_row + 1;
          end
        end
      end

      // 1: latch and oe signal control
      if (current_state == 1)
      begin
        if(out_clk)
        begin
          latch_signal <= 0;
          current_bit <= 0;
          out_bit <= 0;
          current_state <= 0;
          out_clk_en <= 1;
        end
      end

      cicle_counter <= 0;
    end
  end
*/
   // Output connections
   assign CLK_O = out_clk_o;
   assign LED7 = out_clk_o;
   assign LED8 = CLK_I;

   // Change demux address using current_row
   assign RA = current_row[0];
   assign LED1 = current_row[0];
   assign RB = current_row[1];
   assign LED2 = current_row[1];
   assign RC = current_row[2];
   assign LED3 = current_row[2];
   assign RD = current_row[3];
   assign LED4 = current_row[3];

   // Send color info
   assign R0 = red0;
   assign G0 = green0;
   assign B0 = blue0;
   assign R1 = red1;
   assign G1 = green1;
   assign B1 = blue1;

   // Control signals
   assign LATCH = latch_signal;
   assign LED5 = latch_signal;
   assign OE = ~oe_signal;
   assign LED6 = ~oe_signal;
endmodule // top
