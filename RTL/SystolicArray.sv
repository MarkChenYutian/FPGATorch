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

// TODO: AB SR after shift top element = 0
// A SR order to left

module SystolicArray_SR #(N = 1)
  (input reset, clock, shift, store,
   input [`DATA_WIDTH-1:0] datain,
   output [`DATA_WIDTH-1:0] dataout);

  logic [N-1:0][`DATA_WIDTH-1:0] ShiftReg;
  assign dataout = ShiftReg[N-1];
  
  genvar i;
  generate
    for (i = 0; i < N; i++) begin: SR

      always_ff @(posedge clock) begin
        if (reset) ShiftReg[i] <= `DATA_WIDTH'b0;
        // first reg, store
        else if (store && i == 0) begin
          ShiftReg[i] <= datain;
        end
        // remaining, shift
        else if (shift && i == 0) begin
          ShiftReg[i] <= `DATA_WIDTH'b0;;
        end
        else if (shift && i != 0) begin
          ShiftReg[i] <= ShiftReg[i-1];
        end
      end

    end: SR
  endgenerate

endmodule: SystolicArray_SR

module SystolicArray_Driver
 (input logic clock, reset, start,
  input logic [`READ_BW-1:0][`DATA_WIDTH-1:0] readdata, 
  input logic [`ADDR_WIDTH-1:0] base_A, base_B,
  input logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B,
  output logic read, done
  output logic [`ADDR_WIDTH-1:0] read_addr,
  output logic [7:0][7:0][`DATA_WIDTH-1:0] Out);

  logic [3:0] count_stage;
  logic en_count;
  Counter #(4, 1) Stage(.D(), .en(en_count), .clear(start), .load(),
                        .clock, .up(1'b1), .Q(count_stage));
  
  // Calculate A and B address
  logic [`ADDR_WIDTH-1:0] addr_A1, addr_A2;
  Accum #(`ADDR_WIDTH) AddrA1(.clock, .load(start), .en(en_count),
                            .D(base_A), .offset(dim_col_A), .Q(addr_A1));
  Accum #(`ADDR_WIDTH) AddrA2(.clock, .load(start), .en((en_count && count_stage >= 'd4)),
                            .D(base_A + 'd4), .offset(dim_col_A), .Q(addr_A2));
  
  logic [`ADDR_WIDTH-1:0] addr_B;
  Accum #(`ADDR_WIDTH) AddrB(.clock, .load(start), .en(en_count),
                            .D(base_B), .offset(dim_col_B), .Q(addr_B));

  enum logic [2:0] {WAIT, FETCH_A1, FETCH_A2, FETCH_B1, FETCH_B2,
                    CLEANUP, SHIFT} state, nextState;
  
  always_ff @(posedge clock, posedge reset) begin
    if (reset) state <= WAIT;
    else begin
      state <= nextState;
    end
  end

  logic storeA, storeB, en_SA;
  logic [2:0] store_A_index;

  always_comb begin
    en_count = 'b0;
    read = 'b0;
    read_addr = 'b0;
    storeA = 'b0;
    storeB = 'b0;
    en_SA = 'b0;
    store_A_index = 3'b0;
    case (state)
      WAIT: begin
        if (start) nextState = FETCH_A1;
        else nextState = WAIT;
      end
      FETCH_A1: begin
        nextState = FETCH_A2;
        read = 'b1;
        read_addr = addr_A1;
      end
      FETCH_A2: begin
        nextState = FETCH_B1;
        if (count_stage >= 'd4) begin
          read = 'b1;
          read_addr = addr_A2;
        end
        storeA = 'b1;
        store_A_index = count_stage;
      end
      FETCH_B1: begin
        nextState = FETCH_B2;
        read = 'b1;
        read_addr = addr_B;
        if (count_stage >= 'd4) begin
          storeA = 'b1;
          store_A_index = count_stage - 'd4;
        end
      end
      FETCH_B2: begin
        nextState = CLEANUP;
        read = 'b1;
        read_addr = addr_B + 'd4;
        storeB = 'b1;
      end
      CLEANUP: begin
        nextState = SHIFT;
        en_count = 'b1;
        storeB = 'b1;
      end
      SHIFT: begin
        if (count_stage == 'd8) nextState = WAIT;
        else nextState = FETCH_A1;
        en_SA = 'b1;
      end
    endcase
  end

  // Mat A and Mat B input buffer
  logic [7:0][`DATA_WIDTH-1:0] SA_inputA, SA_inputB;

  // Shape systolic array input
  logic [7:0][`READ_BW-1:0] InputBuff_A;
  genvar k;
  generate
    // Shift and store
    for (k = 0; k < 8; k++) begin: InputBuff_A_SR
      always_ff @(posedge clock) begin
        if (start) InputBuff_A[k] <= 0;
        else if (en_SA && k == 0) begin
          InputBuff_A[k] <= `DATA_WIDTH'b0;
        end
        else if (en_SA && k != 0) begin
          InputBuff_A[k] <= InputBuff_A[k-1];
        end
        else if (storeA && store_A_index == k) begin
          InputBuff_A[k] <= readdata;
        end
      end
    end: InputBuff_A_SR
  endgenerate

  genvar i;
  generate
    for (i = 1; i <= 8; i++) begin: InputBuff_B
      SystolicArray_SR #(i) SR_B(.reset(start), .clock, .shift(en_SA), .store(storeB),
                                 .datain(readdata[i]), .dataout(SA_inputB[i]));
    end: InputBuff_B
  endgenerate

  SystolicArray SA(.reset(start), .clock, .en(en_SA),
                   .A(SA_inputA), .B(SA_inputB), .Out);

endmodule: SystolicArray_Driver

// Perform matrix multiplication using systolic array algorithm
module SystolicArray #(parameter N = 8)
  (input logic reset, clock, en,
   input logic [N-1:0][`DATA_WIDTH-1:0] A, B,
   output logic [N-1:0][N-1:0][`DATA_WIDTH-1:0] Out);
  
  // Input ShiftReg for each processor
  // A: row shift  B: col shift
  logic [N-1:0][N-1:0][`DATA_WIDTH-1:0] A_SR, B_SR;

  genvar r, c;
  generate
    for (r = 0; r < N; r++)
      for (c = 0; c < N; c++) begin: SAProcessor
        always_ff @(posedge clock) begin
          // Handle reset
          if (reset) begin
            A_SR[r][c] <= 'b0;
            B_SR[r][c] <= 'b0;
            Out[r][c] <= 'b0;
          end
          else if (en) begin
            // Mult + Accum
            Out[r][c] <= Out[r][c] + A_SR[r][c]*B_SR[r][c];
            // Handle ShiftReg
            // A
            if (c == 0) begin
              A_SR[r][c] <= A[r];
            end
            else begin
              A_SR[r][c] <= A_SR[r][c-1];
            end
            // B
            if (r == 0) begin
              B_SR[r][c] <= B[c];
            end
            else begin
              B_SR[r][c] <= B_SR[r-1][c];
            end
          end
        end
    end: SAProcessor
  endgenerate

endmodule: SystolicArray