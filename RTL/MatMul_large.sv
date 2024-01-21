`default_nettype none

//`include "Macro.svh"
`ifndef MACRO
  `define MACRO
  `include "Macro.svh"
`endif

typedef struct packed {
    // Updated only at beginning
    logic [`DIM_WIDTH-4:0] dimA1;
    logic [`DIM_WIDTH-4:0] dimA2;
    logic [`DIM_WIDTH-4:0] dimB1;
    logic [`DIM_WIDTH-4:0] dimB2;
    logic [3:0] block_count;
    logic [7:0] total_count;
} block_dim_t;

typedef struct packed {
    // indexs for counters
    logic [`DIM_WIDTH-4:0] Ai; // row of A
    logic [`DIM_WIDTH-4:0] Aj; // elem to compute
    logic [`DIM_WIDTH-4:0] Bj; // col of B
    logic [7:0] total_i;
} mat_ind_t;

module Mult(
    // io with upper level controller
    input logic clock, reset, MatMul_en,
    input meta_data_t op,
    output logic finish,
    // io with memory
    input logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB,
    output mem_t memA, memB, memC);

    logic write;
    logic [`ADDR_WIDTH-1:0] addr;
    logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] writedata;

    logic mult_start, mult_start_NB;
    //logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB;
    logic [`ADDR_WIDTH-1:0] base_A, base_B;
    logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B;
    logic mult_done;
    logic readA, readB;
    logic [`ADDR_WIDTH-1:0]read_addr;
    logic [7:0][7:0][`DATA_WIDTH-1:0] mult_out;

    MultAddr_Driver driver(.*);
    SystolicArray_Driver block_multiplier(.start(mult_start_NB), .done(mult_done), .Out(mult_out), .*);

    always_ff @(posedge clock) begin
        mult_start_NB <= mult_start;
    end
   
    // Interface with memory to top
    assign memA.read = readA;
    assign memA.write = 0;
    assign memA.address = read_addr;
    assign memA.writedata = 0;

    assign memB.read = readB;
    assign memB.write = 0;
    assign memB.address = read_addr;
    assign memB.writedata = 0;

    assign memC.read = 0;
    assign memC.write = write;
    assign memC.address = addr;
    assign memC.writedata = writedata;
endmodule 

module MultAddr_Driver (
    // io with upper level controller
    input logic clock, reset, MatMul_en,
    input meta_data_t op,
    output logic write, finish,
    output logic [`ADDR_WIDTH-1:0] addr,
    output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] writedata,

    // io with 8*8 mult module
    output logic mult_start,
    output logic [`ADDR_WIDTH-1:0] base_A, base_B,
    output logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B,
    input logic mult_done,
    input logic [7:0][7:0][`DATA_WIDTH-1:0] mult_out);
    
    // States
    enum logic [2:0] {WAIT, SEND, SEND_DUM, SEND_ADD, WRITE} state, nextState;

    // Counter Signals
    logic add_start, write_start;
    logic add_done, write_done, write_done_not_NB, block_done, total_done;
    logic clear, clear_accum;

    assign clear_accum = write_done & write_done_not_NB;
    always_ff @(posedge clock) begin
        write_done_not_NB <= ~write_done;
    end



    // Internal registers
    logic [7:0][7:0][`DATA_WIDTH-1:0] temp_mat, acc_mat;

    // adder combinational output
    logic [7:0][7:0][`DATA_WIDTH-1:0] add_mat;

    block_dim_t dim_b;

    always_comb begin
        dim_b.dimA1 = (op.dimA1 >> 3);
        dim_b.dimA2 = (op.dimA2 >> 3);
        dim_b.dimB1 = (op.dimB1 >> 3);
        dim_b.dimB2 = (op.dimB2 >> 3);
        dim_b.block_count = (op.dimA2 >> 3);
        dim_b.total_count = (op.dimA1 >> 3) * (op.dimB2 >> 3);
    end

    // Register loading
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            temp_mat <= 0;
            acc_mat <= 0;
        end
        else if(clear | clear_accum) begin
            temp_mat <= 0;
            acc_mat <= 0;
        end
        else begin
            if(mult_done) begin
                temp_mat <= mult_out;
            end
            if(add_done) begin
                acc_mat <= add_mat;
            end
        end
    end

    // 8 * 8 block adder
    
    genvar i,j;
    generate
        for (i = 0; i < 8; i++) 
            for (j = 0; j < 8; j++)begin
                add_cycle_7_area add (.clock,
                                        .dataa(temp_mat[i][j]),
                                        .datab(acc_mat[i][j]),
                                        .nan(),
                                        .overflow(),
                                        .result(add_mat[i][j]),
                                        .underflow(),
                                        .zero());
        end
    endgenerate

    // adder counter
    logic [2:0] add_i;
    logic add_en;
    assign add_done = (add_i == 3'd7);
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            add_i <= 0;
            add_en <= 0;
        end
        else if(clear) begin
            add_i <= 0;
            add_en <= 0;
        end
        else begin
            if (add_start) begin
                add_i <= 0;
                add_en <= 1;
            end
            else if(add_en) begin
                if (add_i == 3'd7) add_en <= 0;
                add_i <= add_i + 1;
            end
        end
    end

    // todo check off by one
    mat_ind_t mat_index;
    logic row_done;
    assign dim_col_A = dim_b.dimA2;
    assign dim_col_B = dim_b.dimB2;
    assign block_done = (mat_index.Aj == dim_b.block_count);
    assign row_done =  (mat_index.Bj == (op.dimB2 >> 3) - 1) & block_done;
    assign total_done = (mat_index.total_i == dim_b.total_count);
    // Address Computation
    always_ff @(posedge clock, posedge reset) begin
        if(reset) mat_index <= 0;
        else if (clear) mat_index <= 0;
        else begin
            if (state == SEND_DUM && block_done) begin
                mat_index.Aj <= 0;
                if(row_done) begin 
                    mat_index.Ai <=  mat_index.Ai + 1;
                    mat_index.Bj <= 0;
                end
                else begin
                    mat_index.Bj <=  mat_index.Bj + 1;
                end
                mat_index.total_i <= mat_index.total_i + 1;
            end
            else if(nextState == SEND_DUM) begin
                mat_index.Aj <=  mat_index.Aj + 1;
            end
        end
    end

    logic [`ADDR_WIDTH-1:0] tmp1;
    assign tmp1 = mat_index.Ai * dim_b.block_count * 8;
    logic [`ADDR_WIDTH-1:0] tmp2;
    assign tmp2 = mat_index.Aj * dim_b.block_count * 8;
    assign base_A = `DATAA_ADDR + tmp1 + mat_index.Aj;
    assign base_B = `DATAB_ADDR + tmp2 + mat_index.Bj;
    
    // Writing fsm
    logic [`ADDR_WIDTH-1:0] base_C, base_C_prev;
    // assign base_C = `RES_ADDR + (mat_index.Ai * dim_b.block_count) * 8 + mat_index.Bj;
    logic mult_start_NB;
    always_ff @(posedge clock) begin
        mult_start_NB <= mult_start;
        if (mult_start_NB) begin
            base_C <= `RES_ADDR + (mat_index.Ai * dim_b.block_count) * 8 + mat_index.Bj;
            base_C_prev <= base_C;
        end
    end

    logic [3:0] write_i;
    assign write_done = (write_i == 4'd8);
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            write_i <= 0;
            write <= 0;
        end
        else if(clear) begin
            write_i <= 0;
            write <= 0;
        end
        else begin
            if (write_start) begin
                write_i <= 0;
                write <= 1;
                addr <= base_C_prev;
                writedata <= add_mat[0];
            end
            else if(write) begin
                if (write_i == 4'd7) begin
                    write <= 0;
                end
                addr <= base_C_prev + (write_i + 1) * dim_b.block_count;
                writedata <= add_mat[write_i + 1];
                write_i <= write_i + 1;
            end
        end
    end


    // FSM
  
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= WAIT;
        else begin
            state <= nextState;
          end
    end

    logic block_done_fsm;
    always_ff @(posedge clock) begin
        if (reset) block_done_fsm <= 0;
        else if (state == SEND_DUM && block_done) block_done_fsm <= 1;
        else if (state == SEND_ADD && add_done)  block_done_fsm <= 0;
    end


    always_comb begin
        add_start = 1'b0;
        write_start = 1'b0;
        mult_start = 1'b0;
        clear = 1'b0;
        finish = 1'b0;
        case (state)
          WAIT: begin
            if (MatMul_en) begin 
                nextState = SEND;
                mult_start = 1'b1;
            end
            else nextState = WAIT;
          end
          SEND: begin
            if (mult_done)  begin 
                nextState = SEND_DUM;
                add_start = 1'b1;
            end
            else nextState = SEND;
          end
          SEND_DUM: begin
                nextState = SEND_ADD;
                if (!total_done) mult_start = 1'b1;
          end
          SEND_ADD: begin
            if (add_done) begin 
                nextState = SEND;
                // assume block_done is always asserted when total_done
                if (block_done_fsm) write_start = 1'b1;
                if (total_done) nextState = WRITE;
            end
            else nextState = SEND_ADD;
          end
          WRITE: begin
            if (write_done) begin 
                nextState = WAIT;
                clear = 1'b1;
                finish = 1'b1;
            end
            else nextState = WRITE;
          end
        endcase
      end
endmodule

module fakememA
  (input logic read, clock, 
   input logic [`ADDR_WIDTH-1:0] read_addr,
   output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] data);

  logic [1023:0][31:0] mem;

  assign mem[255:0] = {$shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(5)};
  //assign mem[133:70] = {$shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(4)};

  always_ff @(posedge clock) begin
    if (read) data <= {mem[read_addr+7], mem[read_addr+6], mem[read_addr+5], mem[read_addr+4],
                       mem[read_addr+3], mem[read_addr+2], mem[read_addr+1], mem[read_addr]};
    else data <= 'b0;
  end
endmodule: fakememA

module fakememB
  (input logic read, clock, 
   input logic [`ADDR_WIDTH-1:0] read_addr,
   output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] data);

  logic [1023:0][31:0] mem;

  //assign mem[63:0] = {$shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(5)};
  assign mem[255:0] = {$shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(2)};

  always_ff @(posedge clock) begin
    if (read) data <= {mem[read_addr+7], mem[read_addr+6], mem[read_addr+5], mem[read_addr+4],
                       mem[read_addr+3], mem[read_addr+2], mem[read_addr+1], mem[read_addr]};
    else data <= 'b0;
  end
endmodule: fakememB

module fakememC
  (input logic read, write, clock, 
   input logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] datain,
   input logic [`ADDR_WIDTH-1:0] read_addr,
   output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] data);

  logic [1023:0][31:0] mem;

  always_ff @(posedge clock) begin
    if (read) data <= {mem[read_addr+7], mem[read_addr+6], mem[read_addr+5], mem[read_addr+4],
                       mem[read_addr+3], mem[read_addr+2], mem[read_addr+1], mem[read_addr]};
    else if (write) {mem[read_addr+7], mem[read_addr+6], mem[read_addr+5], mem[read_addr+4],
                     mem[read_addr+3], mem[read_addr+2], mem[read_addr+1], mem[read_addr]} <= datain;
    else data <= 'b0;
  end
endmodule: fakememC

module SystolicArray_TB;

    // io with upper level controller
    logic clock, reset, MatMul_en;
    meta_data_t op;
    logic finish;
    // io with memory
    logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB;
    mem_t memA, memB, memC;

    Mult DUT(.*);

    fakememA FA(.read(memA.read), .clock, .data(readdataA), .read_addr(memA.address*8));
    fakememB FB(.read(memB.read), .clock, .data(readdataB), .read_addr(memB.address*8));
    fakememC FC(.read(memC.read), .write(memC.write), .clock, .data(), .read_addr(memC.address*8), .datain(memC.writedata));

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end
  
    initial begin
        reset <= 1;
        @(posedge clock)
        reset <= 0;
        MatMul_en <= 1;
        op.op_code <= MAT_MUL;
        op.dimA1 <= 16;
        op.dimA2 <= 16;
        op.dimB1 <= 16;
        op.dimB2 <= 16;
        @(posedge clock)
        MatMul_en <= 0;
        @(posedge clock)
        //#2150
        //#10000
        
        @(posedge finish)
        @(posedge clock)
        $finish;
    end

endmodule: SystolicArray_TB