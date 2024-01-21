`default_nettype none

`ifndef MACRO
  `define MACRO
  `include "Macro.svh"
`endif

module FSM
  (input logic clock, reset,
   input meta_data_t meta_data,
   input logic MatMul_done,
   input logic [`SINGLE_ACCESS-1:0][`BANDWIDTH-1:0][`DATA_WIDTH-1:0] dataRes,
   input mem_t memA_Mul, memB_Mul, memRes_Mul,
   output meta_data_t meta_data_reg,
   output mem_t memOp, memA, memB, memRes,
   output logic idle, save_op, save_scalar, save_Res,
   output logic [`SINGLE_ACCESS-1:0] save_A, save_B);

  enum logic [2:0] {WAIT_OP, MUL, READ_SCALAR, READ, COMPUTE, WRITE} state, nextState;

  logic [`ADDR_WIDTH-1:0] read_ptr, write_ptr, block_ptr;
  logic [(`DIM_WIDTH-$clog2(`BANDWIDTH))*2-1:0] dim_total;
  logic [`CYCLE_WIDTH-1:0] op_count, op_cycle;
  logic read_next, write_next, next_block, op_compute;
  
  Counter #(`ADDR_WIDTH, 1) read_count (.D(0), .en(read_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(read_ptr));
  Counter #(`ADDR_WIDTH, 1) write_count (.D(0), .en(write_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(write_ptr));
  
  Counter #(`ADDR_WIDTH, `SINGLE_ACCESS) block_count (.D(0), .en(next_block), .clear(reset), .load(idle), .clock, .up(1'b1), .Q(block_ptr));

  Counter #(`CYCLE_WIDTH, 1) compute (.D(0), .en(op_compute), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(op_count));

  Register #(`DATA_WIDTH) reg_op (.D(meta_data), .en(save_op), .clear(idle), .clock, .Q(meta_data_reg));

  assign dim_total = {meta_data_reg.dimA1, meta_data_reg.dimA2};

  always_comb begin
    case (meta_data_reg.op_code)
      MAT_ADD: op_cycle = `CYCLE_ADD;
      MAT_SCAL_MUL: op_cycle = `CYCLE_MUL;
      MAT_SCAL_DIV: op_cycle = `CYCLE_DIV;
      MAT_SCAL_ADD: op_cycle = `CYCLE_ADD;
      MAT_SCAL_INV: op_cycle = `CYCLE_DIV;
      MAT_ELE_MUL: op_cycle = `CYCLE_MUL;
      default: op_cycle = 0;
    endcase
  end

  always_comb begin
    idle = 0;
    memOp = 0;
    memA = 0;
    memB = 0;
    memRes = 0;
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
        if ((meta_data.op_code == MAT_SCAL_MUL) ||
            (meta_data.op_code == MAT_SCAL_DIV) || 
            (meta_data.op_code == MAT_SCAL_ADD) ||
            (meta_data.op_code == MAT_SCAL_INV)) begin
          nextState = READ_SCALAR;
          save_op = 1'b1;
          memOp.read = 1'b1;
          memOp.address = `SCALAR_ADDR;
        end else if ((meta_data.op_code == MAT_ADD) || (meta_data.op_code == MAT_ELE_MUL)) begin
          nextState = READ;
          save_op = 1'b1;
          memA.read = 1'b1;
          memB.read = 1'b1;
          memA.address = `DATAA_ADDR + block_ptr + read_ptr;
          memB.address = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else if (meta_data.op_code == MAT_MUL) begin
          nextState = MUL;
          save_op = 1'b1;
          memA.read = memA_Mul.read;
          memB.read = memB_Mul.read;
          memA.address = memA_Mul.address;
          memB.address = memB_Mul.address;
        end else begin
          nextState = WAIT_OP;
          idle = 1'b1;
          memOp.read = 1'b1;
          memOp.address = `OP_ADDR;
        end
      end
      MUL: begin
        if (~MatMul_done) begin
          nextState = MUL;
          memA = memA_Mul;
          memB = memB_Mul;
          memRes = memRes_Mul;
        end else begin
          nextState = WAIT_OP;
          memOp.write = 1'b1;
          memOp.address = `OP_ADDR;
          memOp.writedata = 0;
        end
      end
      READ_SCALAR: begin
        nextState = READ;
        memA.read = 1'b1;
        memB.read = meta_data_reg.op_code == MAT_ADD;
        memA.address = `DATAA_ADDR + block_ptr + read_ptr;
        memB.address = `DATAB_ADDR + block_ptr + read_ptr;
        read_next = 1'b1;
        save_scalar = 1'b1;
      end
      READ: begin
        save_A[read_ptr-1] = 1'b1;
        save_B[read_ptr-1] = meta_data_reg.op_code == MAT_ADD;
        if (read_ptr < `SINGLE_ACCESS) begin
          memA.read = 1'b1;
          memB.read = meta_data_reg.op_code == MAT_ADD;
          memA.address = `DATAA_ADDR + block_ptr + read_ptr;
          memB.address = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else begin
          nextState = COMPUTE;
          op_compute = 1'b1;
        end
      end
      COMPUTE: begin
        if (op_count <= op_cycle) begin
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
          memRes.write = 1'b1;
          memRes.address = `RES_ADDR + block_ptr + write_ptr;
          memRes.writedata = dataRes[write_ptr];
          write_next = 1'b1;
        end else if ((block_ptr + `SINGLE_ACCESS) < dim_total) begin
          next_block = 1'b1;
          nextState = READ;
          memA.read = 1'b1;
          memB.read = meta_data_reg.op_code == MAT_ADD;
          memA.address = `DATAA_ADDR + block_ptr + read_ptr;
          memB.address = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else begin
          nextState = WAIT_OP;
          memOp.write = 1'b1;
          memOp.address = `OP_ADDR;
          memOp.writedata = 0;
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


module MatMem
 (input logic clock, reset,
  output mem_t memOp, memA, memB, memRes,
  input logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataOp, readdataA, readdataB);

  meta_data_t meta_data, meta_data_reg;
  mem_t memA_Mul, memB_Mul, memRes_Mul;
  logic [`SINGLE_ACCESS-1:0][`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA_reg, readdataB_reg, dataRes, dataRes_reg, dataRes_Add, dataRes_ScalMul, dataRes_Div;
  logic [`DATA_WIDTH-1:0] scalar_reg;
  logic idle, save_op, save_scalar, save_Res, MatMul_done;
  logic [`SINGLE_ACCESS-1:0] save_A, save_B;

  FSM fsm (.meta_data(readdataOp), .*);

  Register #(`DATA_WIDTH*`BANDWIDTH) reg_scalar (.D(readdataOp), .en(save_scalar), .clear(idle), .clock, .Q(scalar_reg));

  genvar i, j;
  generate
    for (i = 0; i < `SINGLE_ACCESS; i = i + 1)
    begin : multiple_reg
      Register #(`DATA_WIDTH*`BANDWIDTH) regA (.D(readdataA), .en(save_A[i]), .clear(idle), .clock, .Q(readdataA_reg[i]));
      Register #(`DATA_WIDTH*`BANDWIDTH) regB (.D(readdataB), .en(save_B[i]), .clear(idle), .clock, .Q(readdataB_reg[i]));
      Register #(`DATA_WIDTH*`BANDWIDTH) regRes (.D(dataRes[i]), .en(save_Res), .clear(idle), .clock, .Q(dataRes_reg[i]));

      for (j = 0; j < `BANDWIDTH; j = j + 1)
      begin : multiple_bandwidth
        MatAdd add (.clock, .reset, .dataA(readdataA_reg[i][j]),
                    .dataB((meta_data_reg.op_code == MAT_ADD) ? readdataB_reg[i][j] : scalar_reg),
                    .dataC(dataRes_Add[i][j]));
        MatScalMul mult (.clock, .reset, .dataA(readdataA_reg[i][j]),
                         .dataB((meta_data_reg.op_code == MAT_ELE_MUL) ? readdataB_reg[i][j] : scalar_reg), .dataRes(dataRes_ScalMul[i][j]));
        MatDiv div (.clock, .reset, .dataA((meta_data_reg.op_code == MAT_SCAL_DIV) ? readdataA_reg[i][j] : 32'h3F800000),
                    .dataB((meta_data_reg.op_code == MAT_SCAL_DIV) ? scalar_reg : readdataA_reg[i][j]), .dataRes(dataRes_Div[i][j]));
      end : multiple_bandwidth
    end : multiple_reg
  endgenerate

  Mult matmul (.clock, .reset, .MatMul_en(meta_data_reg.op_code == MAT_MUL), .op(meta_data_reg), .finish(MatMul_done),
               .readdataA, .readdataB, .memA(memA_Mul), .memB(memB_Mul), .memC(memRes_Mul));

  always_comb begin
    case (meta_data_reg.op_code)
      MAT_ADD: dataRes = dataRes_Add;
      MAT_SCAL_MUL: dataRes = dataRes_ScalMul;
      MAT_SCAL_DIV: dataRes = dataRes_Div;
      MAT_SCAL_ADD: dataRes = dataRes_Add;
      MAT_SCAL_INV: dataRes = dataRes_Div;
      MAT_ELE_MUL: dataRes = dataRes_ScalMul;
      default: dataRes = 0;
    endcase
  end

endmodule : MatMem


module MatMem_test();

 logic clock, reset;

 MatMem_unpack dut (.clock, .reset);

 initial begin
   clock = 1'b0;
   forever #5 clock = ~clock;
 end

 initial begin
   reset = 1'b0;
   reset <= 1'b1;

   @(posedge clock);
   reset <= 1'b0;

   #10000;

   $finish;
 end

endmodule : MatMem_test


module MatAdd
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


module MatScalMul
  (input logic clock, reset,
   input logic [`DATA_WIDTH-1:0] dataA, dataB,
   output logic [`DATA_WIDTH-1:0] dataRes);

  mult_cycle_5 mult (
    .clock,
    .dataa(dataA),
    .datab(dataB),
    .nan(),
    .overflow(),
    .result(dataRes),
    .underflow(),
    .zero());

endmodule : MatScalMul


module MatDiv
  (input logic clock, reset,
   input logic [`DATA_WIDTH-1:0] dataA, dataB,
   output logic [`DATA_WIDTH-1:0] dataRes);

  div_cycle_6_area div (
    .clock,
    .dataa(dataA),
    .datab(dataB),
    .division_by_zero(),
    .nan(),
    .overflow(),
    .result(dataRes),
    .underflow(),
    .zero());

endmodule : MatDiv


module MatMem_unpack
 (input logic clock, reset,
  output logic [10:0]  fpga_mem_a_address,                      //                    fpga_mem.address
	output logic         fpga_mem_a_chipselect,                   //                            .chipselect
	output logic         fpga_mem_a_clken,                        //                            .clken
	output logic         fpga_mem_a_write,                        //                            .write
	input logic  [255:0] fpga_mem_a_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_a_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_a_byteenable,                   //                            .byteenable
	
	output logic [10:0]  fpga_mem_b_address,                      //                    fpga_mem.address
	output logic         fpga_mem_b_chipselect,                   //                            .chipselect
	output logic         fpga_mem_b_clken,                        //                            .clken
	output logic         fpga_mem_b_write,                        //                            .write
	input logic  [255:0] fpga_mem_b_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_b_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_b_byteenable,                   //                            .byteenable

  output logic [10:0]  fpga_mem_c_address,                      //                    fpga_mem.address
	output logic         fpga_mem_c_chipselect,                   //                            .chipselect
	output logic         fpga_mem_c_clken,                        //                            .clken
	output logic         fpga_mem_c_write,                        //                            .write
	input logic  [255:0] fpga_mem_c_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_c_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_c_byteenable,

  output logic [9:0]   instruction_mem_address,               //             instruction_mem.address
  output logic         instruction_mem_chipselect,            //                            .chipselect
  output logic         instruction_mem_clken,                 //                            .clken
  output logic         instruction_mem_write,                 //                            .write
  input logic  [31:0]  instruction_mem_readdata,              //                            .readdata
  output logic [31:0]  instruction_mem_writedata,             //                            .writedata
  output logic [3:0]   instruction_mem_byteenable            //                            .byteenable
);
  
  mem_t memOp, memA, memB, memRes;
  logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataOp, readdataA, readdataB;
  MatMem MM(.*);

  // M10KControl mem (.read, .write, .address(mem_addr), .writedata(mem_data), .readdata(data));
  fakemem_readA fakememA (.clock, .read(memA.read), .address(memA.address*8), .readdata(readdataA));
  fakemem_readB fakememB (.clock, .read(memB.read), .address(memB.address*8), .readdata(readdataB));
  fakemem fakememop (.clock, .read(memOp.read), .write(memOp.write), .address(memOp.address), .writedata(memOp.writedata), .readdata(readdataOp));
  fakemem_write fakememRes (.clock, .write(memRes.write), .address(memRes.address*8), .writedata(memRes.writedata));
  
  /*
  always_comb begin
    fpga_mem_a_address = memA.address;
    fpga_mem_a_chipselect = memA.read | memA.write;
    fpga_mem_a_clken = 1'b1;
    fpga_mem_a_write = memA.write;
    readdataA = fpga_mem_a_readdata;
    fpga_mem_a_writedata = memA.writedata;
    fpga_mem_a_byteenable = 32'hFFFFFFFF;
    
    fpga_mem_b_address = memB.address;
    fpga_mem_b_chipselect = memB.read | memB.write;
    fpga_mem_b_clken = 1'b1;
    fpga_mem_b_write = memB.write;
    readdataB = fpga_mem_b_readdata;
    fpga_mem_b_writedata = memB.writedata;
    fpga_mem_b_byteenable = 32'hFFFFFFFF;

    fpga_mem_c_address = memRes.address;
    fpga_mem_c_chipselect = memRes.read | memRes.write;
    fpga_mem_c_clken = 1'b1;
    fpga_mem_c_write = memRes.write;
    // fpga_mem_c_readdata = readdataRes;
    fpga_mem_c_writedata = memRes.writedata;
    fpga_mem_c_byteenable = 32'hFFFFFFFF;

    instruction_mem_address = memOp.address;
    instruction_mem_chipselect = memOp.read | memOp.write;
    instruction_mem_clken = 1'b1;
    instruction_mem_write = memOp.write;
    readdataOp = instruction_mem_readdata;
    instruction_mem_writedata = memOp.writedata;
    instruction_mem_byteenable = 4'hF;
  end */

endmodule: MatMem_unpack
