`define OP_ADDR 0
`define SCALAR_ADDR 1
`define DATAA_ADDR 10
`define DATAB_ADDR 30
`define RES_ADDR 50

`define ADDR_WIDTH 14
`define DATA_WIDTH 32
`define OP_WIDTH 4
`define DIM_WIDTH 7

`define BANDWIDTH 8

`define SINGLE_ACCESS 8

`define CYCLE_WIDTH 3
`define CYCLE_MUL 5
`define CYCLE_DIV 6
`define CYCLE_ADD 7

`timescale 1 ps / 1 ps

typedef enum logic [`OP_WIDTH-1:0] {
  NONE = 0,
  MAT_ADD = 1,
  MAT_SCAL_MUL = 2,
  MAT_SCAL_DIV = 3,
  MAT_SCAL_ADD = 4,
  MAT_SCAL_INV = 5,
  MAT_MUL = 6,
  MAT_TRAS = 7,
  REDUCE_SUM = 8
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