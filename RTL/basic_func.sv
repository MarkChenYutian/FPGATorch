`default_nettype none

`include "parameter.svh"

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


module ALU
  (input logic clock, reset,
   input op_code_t OP,
   output logic done);

  // case operation -> inputs


endmodule : ALU


module FSM
  (input logic clock, reset,
   input meta_data_t meta_data,
   input logic [`SINGLE_ACCESS-1:0][`DATA_WIDTH-1:0] dataRes,
   output logic [`ADDR_WIDTH-1:0] mem_addr,
   output logic [`DATA_WIDTH-1:0] mem_data,
   output logic read, write, idle, save_op, save_scalar, save_Res,
   output logic [`SINGLE_ACCESS-1:0] save_A, save_B);

  enum logic [2:0] {WAIT_OP, READ_SCALAR, READ_A, READ_B, COMPUTE, WRITE} state, nextState;

  logic [`ADDR_WIDTH-1:0] read_ptr, write_ptr, block_ptr;
  logic [`DIM_WIDTH-1:0] dim_total;
  logic [`CYCLE_WIDTH-1:0] op_count, op_cycle;
  logic read_next, write_next, next_block, op_compute;
  
  Counter #(`ADDR_WIDTH, 1) read_count (.D(0), .en(read_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(read_ptr));
  Counter #(`ADDR_WIDTH, 1) write_count (.D(0), .en(write_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(write_ptr));
  
  Counter #(`ADDR_WIDTH, `SINGLE_ACCESS) block_count (.D(0), .en(next_block), .clear(reset), .load(idle), .clock, .up(1'b1), .Q(block_ptr));

  Counter #(`CYCLE_WIDTH, 1) compute (.D(0), .en(op_compute), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(op_count));

  logic [`OP_WIDTH-1:0] op_code;
  logic [`DIM_WIDTH-1:0] dimA1, dimA2, dimB1, dimB2;

  Register #(`OP_WIDTH) reg_op (.D(meta_data.op_code), .en(save_op), .clear(idle), .clock, .Q(op_code));
  Register #(`DIM_WIDTH) reg_dimA1 (.D(meta_data.dimA1), .en(save_op), .clear(idle), .clock, .Q(dimA1));
  Register #(`DIM_WIDTH) reg_dimA2 (.D(meta_data.dimA2), .en(save_op), .clear(idle), .clock, .Q(dimA2));
  Register #(`DIM_WIDTH) reg_dimB1 (.D(meta_data.dimB1), .en(save_op), .clear(idle), .clock, .Q(dimB1));
  Register #(`DIM_WIDTH) reg_dimB2 (.D(meta_data.dimB2), .en(save_op), .clear(idle), .clock, .Q(dimB2));

  assign dim_total = (dimA1 / 4) * (dimA2 / 4);

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

  always_comb begin
    idle = 0;
    mem_addr = 0;
    mem_data = 0;
    read = 1'b0;
    write = 1'b0;
    read_next = 1'b0;
    write_next = 1'b0;
    next_block = 1'b0;
    op_compute = 1'b0;
    save_op = 1'b0;
    save_A = 0;
    save_B = 0;
    save_scalar = 1'b0;
    save_Res = 1'b0;
    case (state)
      WAIT_OP: begin
        if (meta_data.op_code == NONE) begin
          nextState = WAIT_OP;
          idle = 1'b1;
          read = 1'b1;
          mem_addr = `OP_ADDR;
        end else if (meta_data.op_code == MAT_ADD) begin
          nextState = READ_A;
          save_op = 1'b1;
          read = 1'b1;
          mem_addr = `DATAA_ADDR + block_ptr + read_ptr;
        end else begin
          nextState = READ_SCALAR;
          save_op = 1'b1;
          read = 1'b1;
          mem_addr = `SCALAR_ADDR;
        end
      end
      READ_SCALAR: begin
        nextState = READ_A;
        read = 1'b1;
        mem_addr = `DATAA_ADDR + block_ptr + read_ptr;
        read_next = 1'b1;
        save_scalar = 1'b1;
      end
      READ_A: begin
        if (read_ptr < `SINGLE_ACCESS) begin
          read = 1'b1;
          save_A[read_ptr] = 1'b1;
          if (op_code == MAT_ADD) begin
            nextState = READ_B;
            mem_addr = `DATAB_ADDR + block_ptr + read_ptr;
          end else begin
            nextState = READ_A;
            mem_addr = `DATAB_ADDR + block_ptr + read_ptr;
            read_next = 1'b1;
          end
        end else begin
          nextState = COMPUTE;
          op_compute = 1'b1;
        end
      end
      READ_B: begin
        nextState = READ_A;
        read = 1'b1;
        mem_addr = `DATAA_ADDR + block_ptr + read_ptr;
        read_next = 1'b1;
        save_B[read_ptr] = 1'b1;
      end
      COMPUTE: begin
        if (op_count < op_cycle) begin
          nextState = COMPUTE;
          op_compute = 1'b1;
        end else begin
          nextState = WRITE;
          save_Res = 1'b1;
        end
      end
      WRITE: begin
        if (write_ptr < `SINGLE_ACCESS) begin
          nextState = WRITE;
          write = 1'b1;
          mem_addr = `RES_ADDR + block_ptr + write_ptr;
          mem_data = dataRes[write_ptr];
          write_next = 1'b1;
        end else if (block_ptr < dim_total) begin
          next_block = 1'b1;
          nextState = READ_A;
          read = 1'b1;
          mem_addr = `DATAA_ADDR + block_ptr + read_ptr;
        end else begin
          nextState = WAIT_OP;
          write = 1'b1;
          mem_addr = `OP_ADDR;
          mem_data = 0;
        end
      end
    endcase
  end

  always_ff @(posedge clock, posedge reset)
    if (reset)
      state <= WAIT_OP;
    else
      state <= nextState;

endmodule : FSM

/*
module FSM_test();

  logic clock, reset;
  meta_data_t meta_data;
  logic [`SINGLE_ACCESS-1:0][`DATA_WIDTH-1:0] dataRes;
  logic [`ADDR_WIDTH-1:0] mem_addr;
  logic [`DATA_WIDTH-1:0] mem_data;
  logic read, write, idle, save_op, save_scalar, save_Res;
  logic [`SINGLE_ACCESS-1:0] save_A, save_B;

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
    meta_data.op_code <= MAT_ADD;
    meta_data.dimA1 <= 16;
    meta_data.dimA2 <= 24;

    #1000000;

    $finish;
  end

endmodule : FSM_test
*/

module MatMem
  (input logic clock, reset);

  meta_data_t meta_data;
  logic [`ADDR_WIDTH-1:0] mem_addr;
  logic [`SINGLE_ACCESS-1:0][`DATA_WIDTH-1:0] dataA, dataB, dataRes_prep, dataRes;
  logic [`DATA_WIDTH-1:0] mem_data, data;
  logic read, write, idle, save_op, save_scalar, save_Res;
  logic [`SINGLE_ACCESS-1:0] save_A, save_B;

  assign meta_data = data;

  FSM fsm (.clock, .reset, .meta_data, .dataRes, .mem_addr, .mem_data,
           .read, .write, .idle, .save_op, .save_scalar, .save_Res, .save_A, .save_B);

  M10KControl mem (.read, .write, .address(mem_addr), .writedata(mem_data), .readdata(data));

  genvar i;
  generate
    for (i = 0; i < `SINGLE_ACCESS; i = i + 1)
    begin : multiple_reg
      Register #(`DATA_WIDTH) regA (.D(data), .en(save_A[i]), .clear(idle), .clock, .Q(dataA[i]));
      Register #(`DATA_WIDTH) regB (.D(data), .en(save_B[i]), .clear(idle), .clock, .Q(dataB[i]));
      Register #(`DATA_WIDTH) regRes (.D(dataRes_prep[i]), .en(save_Res), .clear(idle), .clock, .Q(dataRes[i]));
      MatAdd add (.clock, .reset, .dataA(dataA[i]), .dataB(dataB[i]), .dataC(dataRes_prep[i]));
    end : multiple_reg
  endgenerate

endmodule : MatMem


module MatMem_test();

  logic clock, reset;

  MatMem dut (.*);

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1'b0;
    reset <= 1'b1;

    #1000000;

    $finish;
  end

endmodule : MatMem_test


module MatAdd // read -> add -> save
  (input logic clock, reset,
   input logic [`DATA_WIDTH-1:0] dataA, dataB,
   output logic [`DATA_WIDTH-1:0] dataC);

  add_cycle_7_area add (.clock,
                        .dataa(dataA),
                        .datab(dataB),
                        .nan(),
                        .overflow(),
                        .result(dataC),
                        .underflow(),
                        .zero());

endmodule : MatAdd
