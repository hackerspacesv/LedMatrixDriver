
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
  parameter TARGET_FREQ = 480000;

  reg [32:0] cicle_counter;
  reg [32:0] prescaler;
  reg [31:0] red0, red1; // Red color registers
  reg [31:0] green0, green1; // Green color registers
  reg [31:0] blue0, blue1; // Blue color registers

  reg [3:0] current_row; // Current row (top/bottom) banks
  reg [6:0] current_bit; // Current bit
  reg [6:0] out_bit; // Current bit
  reg inc_row,latch_signal,oe_signal; // Internal signal registers
  reg oe_output, latch_output;

  reg out_clk; // Output clock
  reg out_clk_en; // Output clock control
  reg out_clk_o;

  reg [1:0] current_state;

  initial begin
    out_clk = 0;
    out_clk_o = 0;
    out_clk_en = 1;
    cicle_counter = 0;
    current_state = 0;
    prescaler = BASE_FREQ/TARGET_FREQ-1;
    // Test color information
    red0 = 32'hAAAAAA00;
    red1 = 32'h55555555;
    green0 = 32'hAAA00AAA;
    green1 = 32'h55555555;
    blue0 = 32'hAA00AAAA;
    blue1 = 32'h55555555;

    current_bit = 5'b0; // Stores the current bit to be sent
    current_row = 4'b1111; // Stores the current row
    inc_row  = 1'b0; // Signal to increase current row
    latch_signal = 1'b0; // Signal to send the latch signal
    oe_signal = 1'b0; // Signal to enable the output
    out_bit = 0;
  end

  always @(out_clk, out_clk_en)
  begin
    out_clk_o = out_clk & out_clk_en;
  end

  // External clock divider
  always @(negedge CLK_I)
  begin
    cicle_counter <= cicle_counter + 1;

    // Internal clock generation
    if (cicle_counter==prescaler)
    begin

      out_clk <= ~out_clk;

      // Normal running counter
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
   assign R0 = red0[out_bit];
   assign G0 = green0[out_bit];
   assign B0 = blue0[out_bit];
   assign R1 = red1[out_bit];
   assign G1 = green1[out_bit];
   assign B1 = blue1[out_bit];

   // Control signals
   assign LATCH = latch_signal;
   assign LED5 = latch_signal;
   assign OE = ~oe_signal;
   assign LED6 = ~oe_signal;
endmodule // top
