`timescale 1ms / 1ms

module led_driver_tb();

  // Clock generation
  reg CLK_I = 0;
  always #10 CLK_I = ~CLK_I;

  // Pin connections
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
    OE,
    LED1,
    LED2,
    LED3,
    LED4,
    LED5,
    LED6,
    LED7,
    LED8;

  // Module initialization
  led_driver #(.BASE_FREQ(12000000),.TARGET_FREQ(12000000)) DUT(
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
    .OE(OE),
    .LED1(LED1),
    .LED2(LED2),
    .LED3(LED3),
    .LED4(LED4),
    .LED5(LED5),
    .LED6(LED6),
    .LED7(LED7),
    .LED8(LED8)
  );

  // Generate output for the wave analyzer
  initial begin
    $dumpfile("led_driver_tb.vcd");
    $dumpvars(0, led_driver_tb);
    # 32256 $finish;
  end

endmodule
