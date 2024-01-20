`default_nettype none

`define SIZE_MAX 64
`define OP_NUM 11

`define OP_ADDR 999
`define DATA_ADDR 999
`define RES_ADDR 999

`define ADDR_WIDTH 12
`define DATA_WIDTH 32
`define OP_WIDTH 4
`define DIM_WIDTH 6

`define READ_BW 4

`define SINGLE_MAT_ADD 8
`define SINGLE_MUL 8
`define SINGLE_DIV 8
`define SINGLE_ADD 8
`define SINGLE_INV 8
`define SINGLE_MAT_MUL 8

module fakemem
  (input logic read, clock, 
   input logic [`ADDR_WIDTH-1:0] read_addr,
   output logic [`READ_BW-1:0][`DATA_WIDTH-1:0] data);

  logic [139:0][31:0] mem;

  assign mem[63:0] = 
  {3, 4, 4, 6, 8, 8, 2, 7, 6, 5, 3, 9, 5, 3, 1, 2, 9, 4, 5, 4, 7, 3, 4, 2, 8, 9, 5, 5, 6, 3, 1, 8, 3, 6, 3, 8, 7, 7, 3, 7, 5, 6, 3, 7, 8, 7, 5, 7, 4, 3, 3, 2, 2, 6, 6, 5, 1, 7, 9, 1, 3, 3, 6, 2};
  assign mem[133:70] = 
  {9, 3, 5, 3, 1, 6, 3, 4, 6, 5, 5, 4, 9, 5, 4, 7, 8, 5, 1, 3, 1, 8, 1, 6, 1, 4, 2, 1, 3, 4, 1, 6, 8, 7, 3, 3, 6, 7, 2, 9, 4, 2, 5, 8, 1, 6, 9, 2, 4, 9, 8, 2, 9, 2, 7, 5, 8, 7, 9, 1, 6, 7, 4, 9};

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
    $display("%d %d %d %d %d %d %d %d\n", Out[0][0], Out[0][1], Out[0][2], Out[0][3], Out[0][4], Out[0][5], Out[0][6], Out[0][7]);
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