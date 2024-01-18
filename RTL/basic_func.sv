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


package OPpkg

  typedef enum logic [$clog(`OP_NUM)-1:0]
    { NONE = 0,
      MAT_ADD = 1,
      MAT_SCAL_MUL = 2,
      MAT_SCAL_DIV = 3,
      MAT_SCAL_ADD = 4,
      MAT_SCAL_INV = 5,
      MAT_MUL = 6,
      MAT_TRAS = 7,
      REDUCE_SUM = 8} op_t;

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
   input logic [$clog(`OP_NUM)-1:0] op_code,
   input logic [`DIM_WIDTH-1:0] dim1, dim2,
   output logic [`ADDR_WIDTH-1:0] mem_addr,
   output logic [`DATA_WIDTH-1:0] mem_data,
   output logic read, write, read_count, write_count);

  enum logic {WAIT, READ, COMPUTE, WRITE} state, nextState;

  logic [`ADDR_WIDTH-1:0] read_ptr, read_single_ptr, write_ptr, write_single_ptr;
  
  Counter #(`ADDR_WIDTH, 1) readAddr (.D(`DATA_ADDR), .en(next), .clear(op_code == NONE), .load(reset), .clock, .Q(read_ptr));
  Counter #(`ADDR_WIDTH, 1) readSingleAddr (.D(), .en(read_single_next), .clear(read_next), .load(), .clock, .Q(read_single_ptr));
  
  Counter #(`ADDR_WIDTH, 1) writeAddr (.D(`RES_ADDR), .en(write_next), .clear(op_code == NONE), .load(reset), .clock, .Q(write_ptr));
  Counter #(`ADDR_WIDTH, 1) writeSingleAddr (.D(), .en(write_single_next), .clear(write_next), .load(), .clock, .Q(write_single_ptr));

  Counter #(`ADDR_WIDTH, 1) compute (.D(), .en(read_next), .clear(), .load(reset), .clock, .Q(read_ptr));

  always_comb begin
    case (op_code)
      NONE: read_cycle = 0;
      MAT_ADD: read_cycle = `SINGLE_MAT_ADD;
      MAT_SCAL_MUL: read_cycle = `SINGLE_MUL;
      MAT_SCAL_DIV: read_cycle = `SINGLE_DIV;
      MAT_SCAL_ADD: read_cycle = `SINGLE_ADD;
      MAT_SCAL_INV: read_cycle = `SINGLE_INV;
      MAT_MUL: read_cycle = `SINGLE_MAT_MUL;
      MAT_TRAS: read_cycle = 0;
      REDUCE_SUM: read_cycle = 0;
      default: read_cycle = 0;
    endcase
  end

  always_comb
    case (state)
      WAIT: nextState = (op_code == NONE) ? WAIT : READ;
      READ: nextState = (read_single_ptr < read_cycle) ? COMPUTE : READ;
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
          mem_addr = `DATA_ADDR + read_ptr;
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
  
  logic [`ADDR_WIDTH-1:0] addr;
  
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
