`default_nettype none

// Perform matrix multiplication using systolic array algorithm
module SystolicArray #(parameter N = 8, W = 32)
  (input logic reset, clock,
   input logic [N-1:0][W-1:0] A, B,
   output logic [N-1:0][N-1:0][W-1:0] Out);
  
  // Input ShiftReg for each processor
  // A: row shift  B: col shift
  logic [N-1:0][N-1:0][W-1:0] A_SR, B_SR;

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
          else begin
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