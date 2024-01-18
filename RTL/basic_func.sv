`default_nettype none

`define SIZE_MAX 64
`define OP_NUM 11

`define OP_ADDR 999
`define DATA_ADDR 999
`define RES_ADDR 999

`define DATA_WIDTH 32
`define OP_WIDTH 4
`define DIM_WIDTH 4
`define DONE_WIDTH 1

`define ADDR_WIDTH 12
`define RES_ADDR 999

package OPpkg

  typedef enum logic [$clog(OP_NUM)-1:0]
    { NONE = 0,
      MAT_ADD = 1,
      MAT_SCAL_MUL = 2,
      MAT_SCAL_DIV = 3,
      MAT_SCAL_ADD = 4,
      MAT_SCAL_INV = 5,
      MAT_SCAL_EXP = 6,
      MAT_SCAL_LOG = 7,
      MAT_MUL = 8,
      MAT_TRAS = 9,
      REDUCE_SUM = 10} op_t;

endpackage : OPpkg


module ALU
  (input logic clock, reset,
   input op_t OP,
   output logic done);

  // case operation -> inputs

  MatMem #(8) mem (.clock, .reset, .addr(), .size0(), .size1(), .size2(), .mat(A));

endmodule : ALU


module FSM
  (input logic clock, reset,
   input logic [$clog(OP_NUM)-1:0] op_code,
   input logic [DIM_WIDTH-1:0] dim1, dim2,
   output logic [ADDR_WIDTH-1:0] mem_addr,
   output logic [DATA_WIDTH-1:0] mem_data,
   output logic read, write);

  enum logic {WAIT, COMPUTE} state, nextState;
  
  Counter #(8, 1) countAddr(.D(), .en(nextState == COMPUTE), .clear(op_code == NONE), .load(), .clock, .Q(mat_addr));

  always_comb
    case (state)
      WAIT: nextState = (op_code == NONE) ? WAIT : COMPUTE;
      COMPUTE: nextState = done ? WAIT : COMPUTE;
    endcase

  always_comb begin
    mem_addr = 0;
    mem_data = 0;
    read = 1'b0;
    write = 1'b0;
    case (state)
      WAIT: begin
        if (op_code == NONE) begin
          read = 1'b1;
          mem_addr = OP_ADDR;
        end else begin
          read = 1'b1;
          mem_addr = DATA_ADDR;
        end
      end
      READ: begin
        if (MAT_ADDR < dim1 * dim2) begin
          read = 1'b1;
          mem_addr = `DATA_ADDR + mat_addr;
        end else begin
          write = 1'b1;
          mem_data = 0;
          mem_addr = `OP_ADDR;
        end
      end
    endcase
  end

  always_ff @(posedge clock, posedge reset)
    if (reset)
      state <= WAIT;
    else
      state <= nextState;

endmodule : FSM


module MatMem
  (input logic clock, reset);
  
  logic [ADDR_WIDTH-1:0] addr;
  
  FSM fsm (.clock, .reset, .op_code, .MAT_ADDR, .mem_addr, .mem_data, .read, .write);

  MemControl mem (.clock, .data, .address(), .read(), .write(), .output(dataA));
  
  Counter #(8, 1) count0(.D(), .en(), .clear(), .load(), .clock, .Q());

endmodule : MatMem


module MatAdd // read -> add -> save
 #(parameter SIZE_SINGLE = 8) // depend on #adders
  (input logic clock, reset,
   input logic [W-1:0] dataA, dataB,
   output logic [W-1:0] dataC);

  add_cycle_7_area (.clock,
                    .dataa(dataA),
                    .datab(dataB),
                    .nan(),
                    .overflow(),
                    .result(dataC),
                    .underflow(),
                    .zero());

endmodule : MatAdd


module MatTrans
  (parameter DIM0_MAX = 2,
             SIZE_MAX = 64,
             W = 23)
  (input logic clock, reset,
   input logic size0, size1, size2);

  // Set(B, i, k, j, Get(A, i, j, k));
  // compute addrA and addrB, read -> switch position -> write

endmodule : MatTrans


module ReduceSum
  (parameter SIZE_MAX = 64,
             SIZE_SINGLE = 8,
             W = 32)
  (input logic clock, reset,
   input logic [SIZE_SINGLE*SIZE_SINGLE][W-1:0] A, B,
   output logic [SIZE_SINGLE*SIZE_SINGLE][W-1:0] C);

  // dim = 0: add i, Set(Result, 0, j, k, value);
  // dim = 1: add j, Set(Result, i, 0, k, value);
  // dim = 2: add k, Set(Result, i, 0, k, value); not yet implemented in C!


endmodule : ReduceSum
