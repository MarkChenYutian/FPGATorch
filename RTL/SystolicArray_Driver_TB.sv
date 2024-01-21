`default_nettype none

`include "Macro.svh"

module SystolicArray_TB;
  logic clock, reset, start, readA, readB, done;
  logic write;
  logic [`ADDR_WIDTH-1:0] read_addr;
  logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB;
  logic [`ADDR_WIDTH-1:0] base_A, base_B;
  logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B;
  logic [7:0][7:0][`DATA_WIDTH-1:0] Out;

  assign base_A = 'd0;
  assign base_B = 'd70;
  assign dim_col_A = 'd8;
  assign dim_col_B = 'd8;

  SystolicArray_Driver DUT(.*);
  fakemem F(.read(readA | readB), .write, .clock, .data(readdataA), .addr(read_addr));
  assign readdataB = readdataA;

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end
  
  initial begin
    reset <= 1;
    @(posedge clock)
    reset <= 0;
    start <= 1;
    @(posedge clock)
    start <= 0;
    @(posedge clock)
    #2150
    // @(posedge clock)
    // start <= 1;
    // @(posedge clock)
    // start <= 0;
    // @(posedge clock)
    // #300
    $display("%h %h %h %h %h %h %h %h\n", Out[0][0], Out[0][1], Out[0][2], Out[0][3], Out[0][4], Out[0][5], Out[0][6], Out[0][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[1][0], Out[1][1], Out[1][2], Out[1][3], Out[1][4], Out[1][5], Out[1][6], Out[1][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[2][0], Out[2][1], Out[2][2], Out[2][3], Out[2][4], Out[2][5], Out[2][6], Out[2][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[3][0], Out[3][1], Out[3][2], Out[3][3], Out[3][4], Out[3][5], Out[3][6], Out[3][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[4][0], Out[4][1], Out[4][2], Out[4][3], Out[4][4], Out[4][5], Out[4][6], Out[4][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[5][0], Out[5][1], Out[5][2], Out[5][3], Out[5][4], Out[5][5], Out[5][6], Out[5][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[6][0], Out[6][1], Out[6][2], Out[6][3], Out[6][4], Out[6][5], Out[6][6], Out[6][7]);
    $display("%h %h %h %h %h %h %h %h\n", Out[7][0], Out[7][1], Out[7][2], Out[7][3], Out[7][4], Out[7][5], Out[7][6], Out[7][7]);
    @(posedge clock)
    $finish;
  end

endmodule: SystolicArray_TB