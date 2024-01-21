`include "Macro.svh"

module Register
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, clock,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clock)
    if (en)
      Q <= D;
    else if (clear)
      Q <= '0;
      
endmodule : Register


module Counter
  #(parameter WIDTH=8,
              STEP=1)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, load, clock, up,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clock)
    if (clear)
      Q <= {WIDTH {1'b0}};
    else if (load)
      Q <= D;
    else if (en)
      if (up)
        Q <= Q + STEP;
      else
        Q <= Q - STEP;
        
endmodule : Counter


module Accum
  #(parameter WIDTH = 8)
  (input logic [WIDTH-1:0] D, offset,
   input logic en, clock, load,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
      Q <= Q + offset;

endmodule: Accum