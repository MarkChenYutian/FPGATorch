`default_nettype none

module SystolicArray_TB;
  logic clock, reset, en;
  logic [1:0][31:0] A, B;
  logic [1:0][1:0][31:0] Out;

  SystolicArray #(2, 32) DUT(.*);

  logic [2:0][1:0][31:0] A_input, B_input;
  always_comb begin
    A_input[0] = {0, 32'd3};
    A_input[1] = {32'd4, 32'd6};
    A_input[2] = {32'd5, 0};
    // 6 3
    // 5 4

    B_input[0] = {0, 32'd2};
    B_input[1] = {32'd1, 32'd10};
    B_input[2] = {32'd8, 0};
    // 10 8
    // 2 1

  end

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end
  
  initial begin
    $monitor($time,, ", %d %d \\ %d %d", Out[0][0], Out[0][1], Out[1][0], Out[1][1]);
    reset <= 1;
    @(posedge clock)
    reset <= 0;
    en <= 1;
    A <= A_input[0];
    B <= B_input[0];
    @(posedge clock)
    A <= A_input[1];
    B <= B_input[1];
    @(posedge clock)
    A <= A_input[2];
    B <= B_input[2];
    @(posedge clock)
    A <= 64'b0;
    B <= 64'b0;
    @(posedge clock)
    @(posedge clock)
    @(posedge clock)
    #30
    $finish;
  end

endmodule: SystolicArray_TB