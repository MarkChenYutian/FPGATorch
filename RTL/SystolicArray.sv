`default_nettype none

`include "Macro.svh"

`timescale 1 ps / 1 ps

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
          ShiftReg[i] <= `DATA_WIDTH'b0;
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
  input logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] readdata, 
  input logic [`ADDR_WIDTH-1:0] base_A, base_B,
  input logic [`DIM_WIDTH-1:0] dim_col_A, dim_col_B,
  output logic readA, readB, done,
  output logic [`ADDR_WIDTH-1:0] read_addr,
  output logic [7:0][7:0][`DATA_WIDTH-1:0] Out);

  logic [4:0] count_stage;
  logic en_count;
  Counter #(5, 1) Stage(.D(), .en(en_count), .clear(start), .load(),
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

  enum logic [3:0] {WAIT, FETCH_A1, FETCH_A2, FETCH_B1, FETCH_B2,
                    CLEANUP, DUM1, DUM2, SHIFT, DONE} state, nextState;
  
  always_ff @(posedge clock, posedge reset) begin
    if (reset) state <= WAIT;
    else begin
      state <= nextState;
    end
  end

  logic storeA, storeB1, storeB2, en_SA;
  logic [2:0] store_A_index;

  always_comb begin
    en_count = 'b0;
    readA = 'b0;
    readB = 'b0;
    read_addr = 'b0;
    storeA = 'b0;
    storeB1 = 'b0;
    storeB2 = 'b0;
    en_SA = 'b0;
    store_A_index = 3'b0;
    done = 'b0;
    case (state)
      WAIT: begin
        if (start) nextState = FETCH_A1;
        else nextState = WAIT;
      end
      FETCH_A1: begin
        nextState = FETCH_A2;
        if (count_stage < 8) begin
          readA = 'b1;
          read_addr = addr_A1;
        end
      end
      FETCH_A2: begin
        nextState = FETCH_B1;
        if (count_stage < 12) begin
          if (count_stage >= 'd4) begin
            readA = 'b1;
            read_addr = addr_A2;
          end
          storeA = 'b1;
          store_A_index = count_stage;
        end
      end
      FETCH_B1: begin
        nextState = FETCH_B2;
        // After 8 iterations all B data are loaded, only needed to advance the buffer
        if (count_stage < 12) begin
          if (count_stage < 8) begin
            readB = 'b1;
            read_addr = addr_B;
          end
          if (count_stage >= 'd4) begin
            storeA = 'b1;
            store_A_index = count_stage - 'd4;
          end
        end
      end
      FETCH_B2: begin
        nextState = CLEANUP;
        if (count_stage < 8) begin
          readB = 'b1;
          read_addr = addr_B + 'd4;
          storeB1 = 'b1;
        end
      end
      CLEANUP: begin
        nextState = DUM1;
        en_count = 'b1;
        if (count_stage < 8) begin
          storeB2 = 'b1;
        end
      end
      DUM1: begin
        nextState = DUM2;
      end
      DUM2: begin
        nextState = SHIFT;
      end
      SHIFT: begin
        if (count_stage == 'd25) nextState = DONE;
        else begin
          nextState = FETCH_A1;
          en_SA = 'b1;
        end
      end
      DONE: begin
        nextState = WAIT;
        done <= 'b1;
      end
    endcase
  end

  // Mat A and Mat B input buffer
  logic [7:0][`DATA_WIDTH-1:0] SA_inputA, SA_inputB;

  // Shape systolic array input
  logic [7:0][`BANDWIDTH-1:0][`DATA_WIDTH-1:0] InputBuff_A;
  genvar n;
  generate
    for (n = 0; n < 8; n++) begin: SA_inputA_assign
      always_comb begin
        SA_inputA[n] = InputBuff_A[n][0];
      end
    end: SA_inputA_assign
  endgenerate

  genvar k, m;
  generate
    // Shift and store
    for (k = 0; k < 8; k++) 
      for (m = 0; m < 4; m++) begin: InputBuff_A_SR
        always_ff @(posedge clock) begin
          if (start) InputBuff_A[k][m] <= 0;
          else if (en_SA && m == 3) begin
            InputBuff_A[k][m] <= 'b0;
          end
          else if (en_SA && m != 3) begin
            InputBuff_A[k][m] <= InputBuff_A[k][m+1];
          end
          else if (storeA && store_A_index == k) begin
            InputBuff_A[k][m] <= readdata[m];
          end
        end
      end: InputBuff_A_SR
  endgenerate

  genvar i;
  generate
    for (i = 1; i <= 4; i++) begin: InputBuff_B1
      SystolicArray_SR #(i) SR_B(.reset(start), .clock, .shift(en_SA), .store(storeB1),
                                 .datain(readdata[i-1]), .dataout(SA_inputB[i-1]));
    end: InputBuff_B1
     for (i = 5; i <= 8; i++) begin: InputBuff_B2
      SystolicArray_SR #(i) SR_B(.reset(start), .clock, .shift(en_SA), .store(storeB2),
                                 .datain(readdata[i-5]), .dataout(SA_inputB[i-1]));
    end: InputBuff_B2
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
  logic [N-1:0][N-1:0][`DATA_WIDTH-1:0] A_SR, B_SR, MultRes, Out_mult_temp, Out_add_temp;

  genvar r, c;
  generate
    for (r = 0; r < N; r++)
      for (c = 0; c < N; c++) begin: SAProcessor

        // Floating mult/add IP
        mult_cycle_5 mult(.clock(clock), .dataa(A_SR[r][c]), .datab(B_SR[r][c]),
                          .nan(), .overflow(), .result(MultRes[r][c]), .underflow(), .zero());
        add_cycle_7_area add(.clock(clock), .dataa(Out[r][c]), .datab(Out_mult_temp[r][c]),
                             .nan(), .overflow(), .result(Out_add_temp[r][c]), .underflow(), .zero());

        always_ff @(posedge clock) begin
          // Handle reset
          if (reset) begin
            A_SR[r][c] <= 'b0;
            B_SR[r][c] <= 'b0;
            Out[r][c] <= 'b0;
            Out_mult_temp[r][c] <= 'b0;
          end
          else if (en) begin
            // Mult + Accum
            Out_mult_temp[r][c] <= MultRes[r][c];
            Out[r][c] <= Out_add_temp[r][c];
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