`default_nettype none

typedef struct packed {
    logic [`DIM_WIDTH-4:0] dimA1;
    logic [`DIM_WIDTH-4:0] dimA2;
    logic [`DIM_WIDTH-4:0] dimB1;
    logic [`DIM_WIDTH-4:0] dimB2;
} block_dim_t;

module MultAddr_Driver (
    // io with upper level controller
    input logic clock, reset, MatMul_en,
    input meta_data_t op,
    output logic write, 
    output logic [`ADDR_WIDTH-1:0] addr,
    output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] writedata;

    // io with 8*8 mult module
    output logic mult_start,
    output logic [`ADDR_WIDTH-1:0] base_A, base_B,
    output logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B,
    input logic mult_done,
    input logic [7:0][7:0][`DATA_WIDTH-1:0] mult_out);
    
    // Counter Signals
    logic setup_start, add_start, write_start;
    logic setup_done, add_done, block_done, total_done;
    logic clear;

    // Internal registers
    logic [7:0][7:0][`DATA_WIDTH-1:0] temp_mat, acc_mat;

    block_dim_t dim_b;

    // Register loading
    always_ff @(posedge clock, posedge reset) begin
        if (dim_en) begin
            dim_b.dimA1 <=(op.dimA1 >> 3);
            dim_b.dimA2 <=(op.dimA2 >> 3);
            dim_b.dimB1 <=(op.dimB1 >> 3);
            dim_b.dimB2 <=(op.dimB2 >> 3);
        end
        if(clear) begin
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
    logic [7:0][7:0][`DATA_WIDTH-1:0] add_mat; // adder combinational output
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

    // setup counter
    logic [2:0] setup_i;
    logic setup_en;
    assign setup_done (add_i == 3'd5);
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            setup_i <= 0;
            setup_en <= 0;
        end
        else begin
            if (setup_start) begin
                setup_i <= 0;
                setup_en <= 1;
            end
            else if(setup_en) begin
                if (setup_i == 3'd4) setup_en <= 0;
                setup_i <= setup_i + 1;
            end
        end
    end







    // FSM
    enum logic [2:0] {WAIT, SETUP, SEND, SEND_ADD} state, nextState;
  
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= WAIT;
        else begin
            state <= nextState;
          end
    end

    always_comb begin
        case (state)
            setup_start = 1'b0;
            add_start = 1'b0;
            write_start = 1'b0;
            mult_start = 1'b0;
            clear = 1'b0;
          WAIT: begin
            if (MatMul_en) begin 
                nextState = SETUP;
                setup_start = 1'b1;
            end
            else nextState = WAIT;
          end
          SETUP: begin
            if (setup_done) begin 
                nextState = SEND;
                mult_start = 1'b1;
            end
            else nextState = SETUP;
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
                if (total_done) nextState = WAIT;
            end
            else nextState = SEND_ADD;
          end
        endcase
      end

endmodule