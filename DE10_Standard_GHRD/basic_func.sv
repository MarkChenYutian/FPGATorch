`default_nettype none

`include "Macro.svh"


module ALU
  (input logic clock, reset,
   input op_code_t OP,
   output logic done);

  // case operation -> inputs


endmodule : ALU


module FSM
  (input logic clock, reset,
   input meta_data_t meta_data,
   input logic [`SINGLE_ACCESS-1:0][`DATA_WIDTH*`BANDWIDTH-1:0] dataRes,
   output op_code_t op_code,
   output logic [`ADDR_WIDTH-1:0] mem_addr_op, mem_addr_A, mem_addr_B, mem_addr_Res,
   output logic [`DATA_WIDTH*`BANDWIDTH-1:0] mem_data_op, mem_data_Res,
   output logic read_op, read_A, read_B, write_op, write_Res,
   output logic idle, save_op, save_scalar, save_Res,
   output logic [`SINGLE_ACCESS-1:0] save_A, save_B);

  enum logic [2:0] {WAIT_OP, READ_SCALAR, READ, COMPUTE, WRITE} state, nextState;

  logic [`ADDR_WIDTH-1:0] read_ptr, write_ptr, block_ptr;
  logic [(`DIM_WIDTH-`BANDWIDTH)*2-1:0] dim_total;
  logic [`CYCLE_WIDTH-1:0] op_count, op_cycle;
  logic read_next, write_next, next_block, op_compute;
  
  Counter #(`ADDR_WIDTH, 1) read_count (.D(0), .en(read_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(read_ptr));
  Counter #(`ADDR_WIDTH, 1) write_count (.D(0), .en(write_next), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(write_ptr));
  
  Counter #(`ADDR_WIDTH, `SINGLE_ACCESS) block_count (.D(0), .en(next_block), .clear(reset), .load(idle), .clock, .up(1'b1), .Q(block_ptr));

  Counter #(`CYCLE_WIDTH, 1) compute (.D(0), .en(op_compute), .clear(reset), .load(next_block | idle), .clock, .up(1'b1), .Q(op_count));

  logic [`DIM_WIDTH-1:0] dimA1, dimA2, dimB1, dimB2;

  Register #(`OP_WIDTH) reg_op (.D(meta_data.op_code), .en(save_op), .clear(idle), .clock, .Q(op_code));
  Register #(`DIM_WIDTH) reg_dimA1 (.D(meta_data.dimA1), .en(save_op), .clear(idle), .clock, .Q(dimA1));
  Register #(`DIM_WIDTH) reg_dimA2 (.D(meta_data.dimA2), .en(save_op), .clear(idle), .clock, .Q(dimA2));
  Register #(`DIM_WIDTH) reg_dimB1 (.D(meta_data.dimB1), .en(save_op), .clear(idle), .clock, .Q(dimB1));
  Register #(`DIM_WIDTH) reg_dimB2 (.D(meta_data.dimB2), .en(save_op), .clear(idle), .clock, .Q(dimB2));

  assign dim_total = (dimA1 / `BANDWIDTH) * (dimA2 / `BANDWIDTH);

  always_comb begin
    case (op_code)
      MAT_ADD: op_cycle = `CYCLE_ADD;
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
    mem_addr_op = 0;
    mem_addr_A = 0;
    mem_addr_B = 0;
    mem_addr_Res = 0;
    mem_data_op = 0;
    mem_data_Res = 0;
    read_op = 1'b0;
    read_A = 1'b0;
    read_B = 1'b0;
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
          read_op = 1'b1;
          mem_addr_op = `SCALAR_ADDR;
        end else if (meta_data.op_code == MAT_ADD) begin
          nextState = READ;
          save_op = 1'b1;
          read_A = 1'b1;
          read_B = 1'b1;
          mem_addr_A = `DATAA_ADDR + block_ptr + read_ptr;
          mem_addr_B = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else begin
          nextState = WAIT_OP;
          idle = 1'b1;
          read_op = 1'b1;
          mem_addr_op = `OP_ADDR;
        end
      end
      READ_SCALAR: begin
        nextState = READ;
        read_A = 1'b1;
        read_B = op_code == MAT_ADD;
        mem_addr_A = `DATAA_ADDR + block_ptr + read_ptr;
        mem_addr_B = `DATAB_ADDR + block_ptr + read_ptr;
        read_next = 1'b1;
        save_scalar = 1'b1;
      end
      READ: begin
        if (read_ptr < `SINGLE_ACCESS) begin
          read_A = 1'b1;
          read_B = 1'b1;
          save_A[read_ptr-1] = 1'b1;
          save_B[read_ptr-1] = 1'b1;
          mem_addr_A = `DATAA_ADDR + block_ptr + read_ptr;
          mem_addr_B = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else begin
          nextState = COMPUTE;
          op_compute = 1'b1;
          save_A[read_ptr-1] = 1'b1;
          save_B[read_ptr-1] = op_code == MAT_ADD;
        end
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
          write_Res = 1'b1;
          mem_addr_Res = `RES_ADDR + block_ptr + write_ptr;
          mem_data_Res = dataRes[write_ptr];
          write_next = 1'b1;
        end else if ((block_ptr + `SINGLE_ACCESS) < dim_total) begin
          next_block = 1'b1;
          nextState = READ;
          read_A = 1'b1;
          read_B = op_code == MAT_ADD;
          mem_addr_A = `DATAA_ADDR + block_ptr + read_ptr;
          mem_addr_B = `DATAB_ADDR + block_ptr + read_ptr;
          read_next = 1'b1;
        end else begin
          nextState = WAIT_OP;
          write_op = 1'b1;
          mem_addr_op = `OP_ADDR;
          mem_data_op = 0;
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
  output logic [10:0]  fpga_mem_a_address,                      //                    fpga_mem.address
	output logic         fpga_mem_a_chipselect,                   //                            .chipselect
	output logic         fpga_mem_a_clken,                        //                            .clken
	output logic         fpga_mem_a_write,                        //                            .write
	input logic  [255:0] fpga_mem_a_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_a_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_a_byteenabl,                   //                            .byteenable
	
	output logic [10:0]  fpga_mem_b_address,                      //                    fpga_mem.address
	output logic         fpga_mem_b_chipselect,                   //                            .chipselect
	output logic         fpga_mem_b_clken,                        //                            .clken
	output logic         fpga_mem_b_write,                        //                            .write
	input logic  [255:0] fpga_mem_b_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_b_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_b_byteenabl,                   //                            .byteenable

  output logic [10:0]  fpga_mem_c_address,                      //                    fpga_mem.address
	output logic         fpga_mem_c_chipselect,                   //                            .chipselect
	output logic         fpga_mem_c_clken,                        //                            .clken
	output logic         fpga_mem_c_write,                        //                            .write
	input logic  [255:0] fpga_mem_c_readdata,                     //                            .readdata
	output logic [255:0] fpga_mem_c_writedata,                    //                            .writedata
	output logic [31:0]  fpga_mem_c_byteenabl,

  output logic [9:0]   instruction_mem_address,               //             instruction_mem.address
  output logic         instruction_mem_chipselect,            //                            .chipselect
  output logic         instruction_mem_clken,                 //                            .clken
  output logic         instruction_mem_write,                 //                            .write
  input logic  [31:0]  instruction_mem_readdata,              //                            .readdata
  output logic [31:0]  instruction_mem_writedata,             //                            .writedata
  output logic [3:0]   instruction_mem_byteenable            //                            .byteenable
);

  meta_data_t meta_data;
  logic [`SINGLE_ACCESS-1:0][`DATA_WIDTH*`BANDWIDTH-1:0] dataA_reg, dataB_reg, dataRes, dataRes_reg;
  op_code_t op_code;
  logic [`DATA_WIDTH*`BANDWIDTH-1:0] data_op, data_op_reg, dataA, dataB;
  logic [`DATA_WIDTH-1:0] scalar_reg;
  logic [`ADDR_WIDTH-1:0] mem_addr_op, mem_addr_A, mem_addr_B, mem_addr_Res;
  logic [`DATA_WIDTH*`BANDWIDTH-1:0] mem_data_op, mem_data_Res;
  logic read_op, read_A, read_B, write_op, write_Res;
  logic idle, save_op, save_scalar, save_Res;
  logic [`SINGLE_ACCESS-1:0] save_A, save_B;

  assign meta_data = data_op;

  FSM fsm (.*);

  // M10KControl mem (.read, .write, .address(mem_addr), .writedata(mem_data), .readdata(data));

  // fakemem memA (.clock, .read(read_A), .write(), .address(mem_addr_A), .writedata(), .readdata(dataA));
  assign fpga_mem_a_address = mem_addr_A;
  assign fpga_mem_a_chipselect = read_A | 1'b0;                   //                            .chipselect
  assign fpga_mem_a_clken = 1'b1;                        //                            .clken
  assign fpga_mem_a_write = 1'b0;                        //                            .write
  assign fpga_mem_a_readdata = dataA;                     //                            .readdata
  assign fpga_mem_a_writedata = 256'd0;                    //                            .writedata
  assign fpga_mem_a_byteenabl = 31'hFFFF_FFFF;                   //                            .byteenable

  // fakemem memB (.clock, .read(read_B), .write(), .address(mem_addr_B), .writedata(), .readdata(dataB));
  assign fpga_mem_b_address = mem_addr_B;
  assign fpga_mem_b_chipselect = read_B | 1'b0;                   //                            .chipselect
  assign fpga_mem_b_clken = 1'b1;                        //                            .clken
  assign fpga_mem_b_write = 1'b0;                        //                            .write
  assign fpga_mem_b_readdata = dataB;                     //                            .readdata
  assign fpga_mem_b_writedata = 256'd0;                    //                            .writedata
  assign fpga_mem_b_byteenabl = 31'hFFFF_FFFF;                   //                            .byteenable

  // fakemem memop (.clock, .read(read_op), .write(write_op), .address(mem_addr_op), .writedata(mem_data_op), .readdata(data_op));
  assign instruction_mem_address = mem_addr_op;               //             instruction_mem.address
  assign instruction_mem_chipselect = read_op | write_op;            //                            .chipselect
  assign instruction_mem_clken = 1'b1;                 //                            .clken
  assign instruction_mem_write = write_op;                 //                            .write
  assign instruction_mem_readdata = data_op;              //                            .readdata
  assign instruction_mem_writedata = mem_data_op;             //                            .writedata
  assign instruction_mem_byteenable = 4'hF;            //                            .byteenable

  // fakemem memRes (.clock, .read(), .write(write_Res), .address(mem_addr_Res), .writedata(mem_data_Res), .readdata());
  assign fpga_mem_c_address = mem_addr_Res;
  assign fpga_mem_c_chipselect = write_Res | 1'b0;                   //                            .chipselect
  assign fpga_mem_c_clken = 1'b1;                        //                            .clken
  assign fpga_mem_c_write = write_Res;                        //                            .write
  assign fpga_mem_c_readdata = 256'd0;                     //                            .readdata
  assign fpga_mem_c_writedata = mem_data_Res;                    //                            .writedata
  assign fpga_mem_c_byteenabl = 31'hFFFF_FFFF;                   //                            .byteenable


  Register #(`DATA_WIDTH*`BANDWIDTH) reg_scalar (.D(data_op), .en(save_scalar), .clear(idle), .clock, .Q(scalar_reg));

  genvar i, j;
  generate
    for (i = 0; i < `SINGLE_ACCESS; i = i + 1)
    begin : multiple_reg
      Register #(`DATA_WIDTH*`BANDWIDTH) regA (.D(dataA), .en(save_A[i]), .clear(idle), .clock, .Q(dataA_reg[i]));
      Register #(`DATA_WIDTH*`BANDWIDTH) regB (.D(dataB), .en(save_B[i]), .clear(idle), .clock, .Q(dataB_reg[i]));
      Register #(`DATA_WIDTH*`BANDWIDTH) regRes (.D(dataRes[i]), .en(save_Res), .clear(idle), .clock, .Q(dataRes_reg[i]));

      for (j = 0; j < `BANDWIDTH; j = j + 1)
      begin : multiple_bandwidth
        MatAdd add (.clock, .reset, .dataA(dataA_reg[i][`DATA_WIDTH*(j+1)-1 : `DATA_WIDTH*j]),
                    .dataB((op_code == MAT_ADD) ? dataB_reg[i][`DATA_WIDTH*(j+1)-1 : `DATA_WIDTH*j] : scalar_reg),
                    .dataC(dataRes[i][`DATA_WIDTH*(j+1)-1 : `DATA_WIDTH*j]));
      end : multiple_bandwidth
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

   @(posedge clock);
   reset <= 1'b0;

   #1000;

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
