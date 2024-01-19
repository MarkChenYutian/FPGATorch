`default_nettype none

`define SIZE_MAX 64

`define OP_ADDR 0
`define SCALAR_ADDR 10
`define DATA_ADDR 100
`define RES_ADDR 200

`define ADDR_WIDTH 12
`define DATA_WIDTH 32
`define OP_WIDTH 4
`define DIM_WIDTH 6

`define READ_BW 4

`define SINGLE_ACCESS 8

`define CYCLE_WIDTH 3
`define CYCLE_MAT_ADD 5
`define CYCLE_MUL 5
`define CYCLE_DIV 5
`define CYCLE_ADD 5
`define CYCLE_INV 5
`define CYCLE_MAT_MUL 5

typedef enum logic [`OP_WIDTH-1:0]
  { NONE = 0,
    MAT_ADD = 1,
    MAT_SCAL_MUL = 2,
    MAT_SCAL_DIV = 3,
    MAT_SCAL_ADD = 4,
    MAT_SCAL_INV = 5,
    MAT_MUL = 6,
    MAT_TRAS = 7,
    REDUCE_SUM = 8} op_t;


module ALU
  (input logic clock, reset,
   input op_t OP,
   output logic done);

  // case operation -> inputs


endmodule : ALU


module FSM
  (input logic clock, reset,
   input logic [`OP_WIDTH-1:0] op_code,
   input logic [`DIM_WIDTH-1:0] dimA1, dimA2,
   output logic [`ADDR_WIDTH-1:0] mem_addr,
   output logic [`DATA_WIDTH-1:0] mem_data,
   output logic read, write);

  enum logic [2:0] {WAIT, READ, READ_B, COMPUTE, WRITE} state, nextState;

  logic [`ADDR_WIDTH-1:0] read_ptr, write_ptr, block_ptr;
  logic [`DIM_WIDTH-1:0] dimA_total;
  logic [`CYCLE_WIDTH-1:0] op_count, op_cycle;
  logic read_next, write_next, next_block, op_compute;
  
  Counter #(`ADDR_WIDTH, 1) read_count (.D(0), .en(read_next), .clear(reset), .load(next_block), .clock, .up(1'b1), .Q(read_ptr));
  Counter #(`ADDR_WIDTH, 1) write_count (.D(0), .en(write_next), .clear(reset), .load(next_block), .clock, .up(1'b1), .Q(write_ptr));
  
  Counter #(`ADDR_WIDTH, `SINGLE_ACCESS) block_count (.D(0), .en(next_block), .clear(reset), .load(op_code == NONE), .clock, .up(1'b1), .Q(block_ptr));

  Counter #(`CYCLE_WIDTH, 1) compute (.D(0), .en(op_compute), .clear(reset), .load(next_block), .clock, .up(1'b1), .Q(op_count));

  assign dimA_total = dimA1 * dimA2;

  always_comb begin
    case (op_code)
      MAT_ADD: op_cycle = `CYCLE_MAT_ADD;
      MAT_SCAL_MUL: op_cycle = `CYCLE_MUL;
      MAT_SCAL_DIV: op_cycle = `CYCLE_DIV;
      MAT_SCAL_ADD: op_cycle = `CYCLE_ADD;
      MAT_SCAL_INV: op_cycle = `CYCLE_INV;
      MAT_MUL: op_cycle = `CYCLE_MAT_MUL;
      default: op_cycle = 0;
    endcase
  end

  always_comb
    case (state)
      WAIT: nextState = (op_code == NONE) ? WAIT : READ;
      READ: begin
        if (read_ptr < `SINGLE_ACCESS)
          if (op_code == MAT_ADD)
            nextState = READ_B;
          else
            nextState = READ;
        else
          nextState = COMPUTE;
      end
      READ_B: nextState = READ;
      COMPUTE: nextState = (op_count < op_cycle) ? COMPUTE : WRITE;
      WRITE: begin
        if (write_ptr < `SINGLE_ACCESS)
          nextState = WRITE;
        else if (block_ptr < dimA_total)
            nextState = READ;
        else
          nextState = WAIT;
      end
    endcase

  always_comb begin
    mem_addr = 0;
    mem_data = 0;
    read = 1'b0;
    write = 1'b0;
    read_next = 1'b0;
    write_next = 1'b0;
    next_block = 1'b0;
    op_compute = 1'b0;
    case (state)
      WAIT: begin
        if (op_code == NONE) begin
          read = 1'b1;
          mem_addr = `OP_ADDR;
        end else begin
          read = 1'b1;
          mem_addr = `SCALAR_ADDR;
        end
      end
      READ: begin
        if (read_ptr < `SINGLE_ACCESS) begin
          read = 1'b1;
          mem_addr = `DATA_ADDR + block_ptr + read_ptr;
          if (op_code != MAT_ADD)
            read_next = 1'b1;
        end else begin
          op_compute = 1'b1;
        end
      end
      READ_B: begin
        read = 1'b1;
        mem_addr = `DATA_ADDR + block_ptr + read_ptr + dimA_total;
        read_next = 1'b1;
      end
      COMPUTE: op_compute = (op_count < op_cycle);
      WRITE: begin
        if (write_ptr < `SINGLE_ACCESS) begin
          write = 1'b1;
          mem_addr = `RES_ADDR + write_ptr;
          write_next = 1'b1;
        end else begin
          next_block = 1'b1;
          write = 1'b1;
          mem_addr = `OP_ADDR;
          mem_data = 0;
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


module FSM_test();

  logic clock, reset;
  logic [`OP_WIDTH-1:0] op_code;
  logic [`DIM_WIDTH-1:0] dimA1, dimA2;
  logic [`ADDR_WIDTH-1:0] mem_addr;
  logic [`DATA_WIDTH-1:0] mem_data;
  logic read, write;

  FSM dut (.*);

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1'b0;
    reset <= 1'b1;

    @(posedge clock);
    reset <= 1'b0;
    op_code <= MAT_ADD;
    dimA1 <= 4;
    dimA2 <= 2;

    #1000000;

    $finish;
  end

endmodule : FSM_test

/*
module MatMem
  (input logic clock, reset);
  
  logic [`ADDR_WIDTH-1:0] addr;
  
  FSM fsm (.clock, .reset, .op_code, .MAT_ADDR, .mem_addr, .mem_data, .read, .write);

  MemControl mem (.clock, .data, .address(), .read(), .write(), .output(dataA));
  
  Counter #(8, 1) count0(.D(), .en(), .clear(), .load(), .clock, .Q());

endmodule : MatMem
*/
/*
module MatAdd // read -> add -> save
 #(parameter SIZE_SINGLE = 8) // depend on #adders
  (input logic clock, reset,
   input logic [`DATA_WIDTH-1:0] dataA, dataB,
   output logic [`DATA_WIDTH-1:0] dataC);

  add_cycle_7_area (.clock,
                    .dataa(dataA),
                    .datab(dataB),
                    .nan(),
                    .overflow(),
                    .result(dataC),
                    .underflow(),
                    .zero());

endmodule : MatAdd
*/