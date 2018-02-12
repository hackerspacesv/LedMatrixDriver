
module led_driver(
  input  CLK_I,
  output R0,
  output G0,
  output B0,
  output R1,
  output G1,
  output B1,
  output RA,
  output RB,
  output RC,
  output RD,
  output CLK_O,
  output LATCH,
  output OE
);
   reg [31:0] red0, red1;
   reg [31:0] green0, green1;
   reg [31:0] blue0, blue1;
   reg [3:0] current_row;
   reg [4:0] current_bit;
   reg inc_row, latch_signal,oe_signal;

   initial begin
    red0 = 32'hAAAAAAAA;
    red1 = 32'h55555555;
    green0 = 32'hAAAAAAAA;
    green1 = 32'h55555555;
    blue0 = 32'hAAAAAAAA;
    blue1 = 32'h55555555;
    current_bit = 5'b0;
    current_row = 4'b1111;
    inc_row  = 1'b0;
    latch_signal = 1'b0;
    oe_signal = 1'b0;
   end
   
   always @(posedge CLK_I) begin
    if (inc_row)
    begin
      current_row <= current_row + 1;
      inc_row <= 0;
    end

    current_bit <= current_bit + 1;

    if (current_bit == 5'd31)
    begin
      inc_row <= 1;
    end
   end

   always @(negedge CLK_I) begin
    if (latch_signal)
    begin
      latch_signal <= 0;
    end

    if (inc_row)
    begin
      latch_signal <= 1;
      oe_signal <= 1;
    end

    if (current_bit == 5'd31)
    begin
      oe_signal <= 0;
    end
   end
   // Multiplexer output
   assign RA = current_row[0];
   assign RB = current_row[1];
   assign RC = current_row[2];
   assign RD = current_row[3];

   // Color info
   assign R0 = red0[current_bit];
   assign G0 = green0[current_bit];
   assign B0 = blue0[current_bit];
   assign R1 = red1[current_bit];
   assign G1 = green1[current_bit];
   assign B1 = blue1[current_bit];
   assign CLK_O = CLK_I; // TODO: Prescale to generate fixed freq CLK_O
   assign LATCH = latch_signal;
   assign OE = oe_signal;
endmodule // top
