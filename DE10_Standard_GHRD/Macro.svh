`define OP_ADDR 0
`define SCALAR_ADDR 1
`define DATAA_ADDR 0
`define DATAB_ADDR 0
`define RES_ADDR 0

`define ADDR_WIDTH 14
`define DATA_WIDTH 32
`define OP_WIDTH 4
`define DIM_WIDTH 7

`define BANDWIDTH 8

`define SINGLE_ACCESS 1

`define CYCLE_WIDTH 4
`define CYCLE_MUL 5
`define CYCLE_DIV 6
`define CYCLE_ADD 7

`timescale 1 ps / 1 ps

typedef enum logic [`OP_WIDTH-1:0] {
  NONE = 4'd0,
  MAT_ADD = 4'd1,
  MAT_SCAL_MUL = 4'd2,
  MAT_SCAL_DIV = 4'd3,
  MAT_SCAL_ADD = 4'd4,
  MAT_SCAL_INV = 4'd5,
  MAT_MUL = 4'd6,
  MAT_ELE_MUL = 4'd7
} op_code_t;

typedef struct packed {
  op_code_t op_code;
  logic [`DIM_WIDTH-1:0] dimA1;
  logic [`DIM_WIDTH-1:0] dimA2;
  logic [`DIM_WIDTH-1:0] dimB1;
  logic [`DIM_WIDTH-1:0] dimB2;
} meta_data_t;

typedef struct packed {
  logic read;
  logic write;
  logic [`ADDR_WIDTH-1:0] address;
  logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] writedata;
} mem_t;