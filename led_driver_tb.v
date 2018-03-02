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
`timescale 1ms / 1ms

module led_driver_tb(); // BEGIN: Test bench for LED Matrix Driver

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
  led_driver #(.BASE_FREQ(12000000),.TARGET_FREQ(6000000)) DUT(
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
    # 400000 $finish;
  end

endmodule // END: Test bench for LED Matrix Driver
