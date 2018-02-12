`timescale 1ms / 1us
module led_driver_tb();

  reg CLK_I = 0;
  always #10 CLK_I = ~CLK_I;

  wire
    R0,
    G0,
    B0,
    R1,
    G1,
    B1,
    RA,
    RB,
    RC,
    RD,
    CLK_O,
    LATCH,
    OE;

  led_driver DUT(
    .CLK_I(CLK_I),
    .R0(R0),
    .G0(G0),
    .B0(B0),
    .R1(R1),
    .G1(G1),
    .B1(B1),
    .RA(RA),
    .RB(RB),
    .RC(RC),
    .RD(RD),
    .CLK_O(CLK_O),
    .LATCH(LATCH),
    .OE(OE)
  );

  initial begin
    $dumpfile("led_driver_tb.vcd");
    $dumpvars(0, led_driver_tb);
    # 10240 $finish;
  end

endmodule
