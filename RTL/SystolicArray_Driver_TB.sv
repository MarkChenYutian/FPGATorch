`default_nettype none

`include "Macro.svh"

module fakemem
  (input logic read, clock, 
   input logic [`ADDR_WIDTH-1:0] read_addr,
   output logic [`READ_BW-1:0][`DATA_WIDTH-1:0] data);

  logic [139:0][31:0] mem;

  assign mem[63:0] = {$shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(3)};
  assign mem[133:70] = {$shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(3)};

  always_ff @(posedge clock) begin
    if (read) data <= {mem[read_addr+3], mem[read_addr+2], mem[read_addr+1], mem[read_addr]};
    else data <= 'b0;
  end

endmodule: fakemem

module SystolicArray_TB;
  logic clock, reset, start, read, done;
  logic [`ADDR_WIDTH-1:0] read_addr;
  logic [`READ_BW-1:0][`DATA_WIDTH-1:0] readdata;
  logic [`ADDR_WIDTH-1:0] base_A, base_B;
  logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B;
  logic [7:0][7:0][`DATA_WIDTH-1:0] Out;

  assign base_A = 'd0;
  assign base_B = 'd70;
  assign dim_col_A = 'd8;
  assign dim_col_B = 'd8;

  SystolicArray_Driver DUT(.*);
  fakemem F(.read, .clock, .data(readdata), .read_addr);

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
    #1500
    // @(posedge clock)
    // start <= 1;
    // @(posedge clock)
    // start <= 0;
    // @(posedge clock)
    // #300
    $display("%h", F.mem[63]);
    $display("%h %d %d %d %d %d %d %d\n", Out[0][0], Out[0][1], Out[0][2], Out[0][3], Out[0][4], Out[0][5], Out[0][6], Out[0][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[1][0], Out[1][1], Out[1][2], Out[1][3], Out[1][4], Out[1][5], Out[1][6], Out[1][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[2][0], Out[2][1], Out[2][2], Out[2][3], Out[2][4], Out[2][5], Out[2][6], Out[2][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[3][0], Out[3][1], Out[3][2], Out[3][3], Out[3][4], Out[3][5], Out[3][6], Out[3][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[4][0], Out[4][1], Out[4][2], Out[4][3], Out[4][4], Out[4][5], Out[4][6], Out[4][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[5][0], Out[5][1], Out[5][2], Out[5][3], Out[5][4], Out[5][5], Out[5][6], Out[5][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[6][0], Out[6][1], Out[6][2], Out[6][3], Out[6][4], Out[6][5], Out[6][6], Out[6][7]);
    $display("%d %d %d %d %d %d %d %d\n", Out[7][0], Out[7][1], Out[7][2], Out[7][3], Out[7][4], Out[7][5], Out[7][6], Out[7][7]);
    @(posedge clock)
    $finish;
  end

endmodule: SystolicArray_TB