// consolidated 7 segment hex display library from 18240 material
// modified to fit the # of hex displays on the DE0-CV board
`default_nettype none

// seven segment display
module BCHtoSevenSegment
  (input  logic [3:0] BCH,
   output logic [6:0] segment);

  always_comb
    unique case (BCH) 
      4'd0: segment = 7'b011_1111;
      4'd1: segment = 7'b000_0110;
      4'd2: segment = 7'b101_1011;
      4'd3: segment = 7'b100_1111;
      4'd4: segment = 7'b110_0110;
      4'd5: segment = 7'b110_1101;
      4'd6: segment = 7'b111_1101;
      4'd7: segment = 7'b000_0111;
      4'd8: segment = 7'b111_1111;
      4'd9: segment = 7'b110_0111;
      4'd10: segment = 7'b111_0111;
      4'd11: segment = 7'b111_1100;
      4'd12: segment = 7'b011_1001;
      4'd13: segment = 7'b101_1110;
      4'd14: segment = 7'b111_1001;
      4'd15: segment = 7'b111_0001;
      default: segment = 7'b000_0000;
    endcase

endmodule : BCHtoSevenSegment


// Module to drive all 8 seven segment display slots with blanking logic
module SevenSegmentDisplay
  (input  logic [3:0] BCH5, BCH4, BCH3, BCH2, BCH1, BCH0,
   input  logic [5:0] blank,
   output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

  logic [6:0] seg5, seg4, seg3, seg2, seg1, seg0;
  logic [6:0] inv5, inv4, inv3, inv2, inv1, inv0;

  assign HEX5 = ~inv5;
  assign HEX4 = ~inv4;
  assign HEX3 = ~inv3;
  assign HEX2 = ~inv2;
  assign HEX1 = ~inv1;
  assign HEX0 = ~inv0;

  BCHtoSevenSegment bss5(.BCH(BCH5), .segment(seg5));
  BCHtoSevenSegment bss4(.BCH(BCH4), .segment(seg4));
  BCHtoSevenSegment bss3(.BCH(BCH3), .segment(seg3));
  BCHtoSevenSegment bss2(.BCH(BCH2), .segment(seg2));
  BCHtoSevenSegment bss1(.BCH(BCH1), .segment(seg1));
  BCHtoSevenSegment bss0(.BCH(BCH0), .segment(seg0));

  Mux2to1 #(7) mux5(.I1(7'b000_0000), .I0(seg5), .Y(inv5), .S(blank[5]));
  Mux2to1 #(7) mux4(.I1(7'b000_0000), .I0(seg4), .Y(inv4), .S(blank[4]));
  Mux2to1 #(7) mux3(.I1(7'b000_0000), .I0(seg3), .Y(inv3), .S(blank[3]));
  Mux2to1 #(7) mux2(.I1(7'b000_0000), .I0(seg2), .Y(inv2), .S(blank[2]));
  Mux2to1 #(7) mux1(.I1(7'b000_0000), .I0(seg1), .Y(inv1), .S(blank[1]));
  Mux2to1 #(7) mux0(.I1(7'b000_0000), .I0(seg0), .Y(inv0), .S(blank[0]));

endmodule : SevenSegmentDisplay