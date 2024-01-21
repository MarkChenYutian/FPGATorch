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
    output finish,
    // io with memory
    input logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB,
    output mem_t memA, memB, memC);

    logic write;
    logic [`ADDR_WIDTH-1:0] addr;
    logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] writedata;

    logic mult_start;
    //logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdataA, readdataB;
    logic [`ADDR_WIDTH-1:0] base_A, base_B;
    logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B;
    logic mult_done;
    logic readA, readB;
    logic [`ADDR_WIDTH-1:0]read_addr;
    logic [7:0][7:0][`DATA_WIDTH-1:0] mult_out;

    MultAddr_Driver driver(.*);
    SystolicArray_Driver block_multiplier(.start(mult_start), .done(mult_done), .Out(mult_out), .*);
   
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
    
    // Counter Signals
    logic add_start, write_start;
    logic add_done, write_done, block_done, total_done;
    logic clear;

    // Internal registers
    logic [7:0][7:0][`DATA_WIDTH-1:0] temp_mat, acc_mat;
    logic [7:0] block_count;

    // adder combinational output
    logic [7:0][7:0][`DATA_WIDTH-1:0] add_mat;

    block_dim_t dim_b;

    // Register loading
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            temp_mat <= 0;
            acc_mat <= 0;
            dim_b <= 0;
        end
        else if(clear) begin
            temp_mat <= 0;
            acc_mat <= 0;
            dim_b <= 0;
        end
        else if (MatMul_en) begin
            dim_b.dimA1 <= (op.dimA1 >> 3);
            dim_b.dimA2 <= (op.dimA2 >> 3);
            dim_b.dimB1 <= (op.dimB1 >> 3);
            dim_b.dimB2 <= (op.dimB2 >> 3);
            dim_b.block_count <= (op.dimA2 >> 3);
            dim_b.total_count <= (op.dimA1 >> 3) * (op.dimB2 >> 3);
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
                if (add_i == 3'd6) add_en <= 0;
                add_i <= add_i + 1;
            end
        end
    end

    // todo check off by one
    mat_ind_t mat_index;
    assign dim_col_A = dim_b.dimA2;
    assign dim_col_B = dim_b.dimB2;
    assign block_done = (mat_index.Aj == dim_b.block_count);
    assign total_done = (mat_index.total_i == dim_b.total_count);
    // Address Computation
    always_ff @(posedge clock, posedge reset) begin
        if(reset) mat_index <= 0;
        else if (clear) mat_index <= 0;
        else begin
            if (block_done) begin
                mat_index.Ai <=  mat_index.Ai + 1;
                mat_index.Bj <=  mat_index.Bj + 1;
                mat_index.Aj <=  0;
            end
            else if(mult_done) begin
                mat_index.Aj <=  mat_index.Aj + 1;
                mat_index.total_i <= mat_index.total_i + 1;
            end
        end
    end

    assign base_A = `DATAA_ADDR + (mat_index.Ai * dim_b.block_count) + mat_index.Aj;
    assign base_B = `DATAB_ADDR + (mat_index.Aj * dim_b.block_count) + mat_index.Bj;
    
    // Writing fsm
    logic [`ADDR_WIDTH-1:0] base_C;
    assign base_C = `RES_ADDR + (mat_index.Ai * dim_b.block_count) + mat_index.Bj;
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
                addr <= base_C;
                writedata <= acc_mat[0];
            end
            else if(write) begin
                if (write_i == 4'd7) begin
                    write <= 0;
                end
                addr <= base_C + write_i * dim_b.block_count;
                writedata <= acc_mat[write_i + 1];
                write_i <= write_i + 1;
            end
        end
    end


    // FSM
    enum logic [2:0] {WAIT, SEND, SEND_ADD, WRITE} state, nextState;
  
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= WAIT;
        else begin
            state <= nextState;
          end
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
                nextState = SEND_ADD;
                mult_start = 1'b1;
                add_start = 1'b1;
            end
            else nextState = SEND;
          end
          SEND_ADD: begin
            if (add_done) begin 
                nextState = SEND;
                // assume block_done is always asserted when total_done
                if (block_done) write_start = 1'b1;
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