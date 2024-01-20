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
    logic add_done, block_done, total_done;

    block_dim_t dim_b;
    always_ff @(posedge clock, posedge MatMul_en) begin
        dim_b.dimA1 <=(op.dimA1 >> 3);
        dim_b.dimA2 <=(op.dimA2 >> 3);
        dim_b.dimB1 <=(op.dimB1 >> 3);
        dim_b.dimB2 <=(op.dimB2 >> 3);
      end

    // FSM
    enum logic [2:0] {WAIT, SEND, SEND_ADD} state, nextState;
  
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= WAIT;
        else begin
            state <= nextState;
        end
    end

    always_comb begin
        case (state)
          WAIT: begin
            if (MatMul_en) nextState = SEND;
            else nextState = WAIT;
          end
          SEND: begin
            if (mult_done) nextState = SEND_ADD;
            else nextState = SEND;
          end
          SEND_ADD: begin
            if (add_done) nextState = SEND;
            else nextState = SEND_ADD;
          end
        endcase
      end

endmodule