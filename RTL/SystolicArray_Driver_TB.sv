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
   output logic [`READ_BW-1:0][`DATA_WIDTH-1:0] data);

  always_ff @(posedge clock) begin
    if (read) data <= {32'h4, 32'h3, 32'h2, 32'h1};
    else data <= 'b0;
  end

endmodule: fakemem

module SystolicArray_TB;
  logic clock, reset, start, read;
  logic [`ADDR_WIDTH-1:0] read_addr;
  logic [`READ_BW-1:0][`DATA_WIDTH-1:0] readdata;
  logic [`ADDR_WIDTH-1:0] base_A, base_B;
  logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B;
  logic [7:0][7:0][`DATA_WIDTH-1:0] Out;

  assign base_A = 'd10;
  assign base_B = 'd70;
  assign dim_col_A = 'd6;
  assign dim_col_B = 'd3;

  SystolicArray_Driver DUT(.*);
  fakemem F(.read, .clock, .data(readdata));

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
    #600
    // @(posedge clock)
    // start <= 1;
    // @(posedge clock)
    // start <= 0;
    // @(posedge clock)
    // #300
    $finish;
  end

endmodule: SystolicArray_TB