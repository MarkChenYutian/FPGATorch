`default_nettype none

// Wrapper handling M10K read and write
module M10KControl
  (input logic read, write,
   input logic [7:0] address,
   output logic [31:0] readdata);

  logic write, chipselect;
  assign chipselect = read | write;

  M10K RAM(.byteenable(4'hF), .*);

endmodule: M10Control

// Dummy M10K
module M10K
  (input logic write, chipselect,
   input logic [7:0] address,
   input logic [3:0] byteenable,
   output logic [31:0] readdata);

   assign readdata = 'b0;

endmodule: M10K