`default_nettype none
// library file from 240 spring 2023, using Registor module
/*
 * A library of components, usable for many future hardware designs.
 */
 
// A Magnitude Comparator does an unsigned comparison of two input values.
module MagComp
  #(parameter   WIDTH = 8)
  (output logic             AltB, AeqB, AgtB,
   input  logic [WIDTH-1:0] A, B);

  assign AeqB = (A == B);
  assign AltB = (A <  B);
  assign AgtB = (A >  B);

endmodule: MagComp

// An Adder is a combinational sum generator.
module Adder
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] A, B,
   input  logic             cin,
   output logic [WIDTH-1:0] sum,
   output logic             cout);
   
   assign {cout, sum} = A + B + cin;
   
endmodule : Adder

// The Multiplexer chooses one of WIDTH bits
module Multiplexer
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0]         I,
   input  logic [$clog2(WIDTH)-1:0] S,
   output logic                     Y);
   
   assign Y = I[S];
   
endmodule : Multiplexer

// The 2-to-1 Multiplexer chooses one of two multi-bit inputs.
module Mux2to1
  #(parameter WIDTH = 8)
  (input  logic [WIDTH-1:0] I0, I1,
   input  logic             S,
   output logic [WIDTH-1:0] Y);
   
  assign Y = (S) ? I1 : I0;
  
endmodule : Mux2to1

// The Decoder converts from binary to one-hot codes.
module Decoder
  #(parameter WIDTH=8)
  (input  logic [$clog2(WIDTH)-1:0] I,
   input  logic                     en,
   output logic [WIDTH-1:0]         D);
   
  always_comb begin
    D = '0;
    if (en)
      D[I] = 1'b1;
  end
  
endmodule : Decoder

// A DFlipFlop stores the input bit synchronously with the clock signal.
// preset and reset are asynchronous inputs.
module DFlipFlop
  (input  logic D,
   input  logic preset_L, reset_L, clock,
   output logic Q);
   
  always_ff @(posedge clock)
    if (~preset_L & reset_L)
      Q <= 1'b1;
    else if (~reset_L & preset_L)
      Q <= 1'b0;
    else if (~reset_L & ~preset_L)
      Q <= 1'bX;
    else
      Q <= D;
    
endmodule : DFlipFlop

// A Register stores a multi-bit value.  
// Enable has priority over Clear
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

// A binary up-down counter.
// Clear has priority over Load, which has priority over Enable
module Counter
  #(parameter WIDTH=8)
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
        Q <= Q + 1'b1;
      else
        Q <= Q - 1'b1;
        
endmodule : Counter

// A Synchronizer takes an asynchronous input and changes it to synchronized
module Synchronizer
  (input  logic async, clock,
   output logic sync);
 
  logic metastable;
    
  DFlipFlop one(.D(async),
                .Q(metastable),
                .clock,
                .preset_L(1'b1), 
                .reset_L(1'b1)
               );

  DFlipFlop two(.D(metastable),
                .Q(sync),
                .clock,
                .preset_L(1'b1), 
                .reset_L(1'b1)
               );

endmodule : Synchronizer

// A PIPO Shift Register, with controllable shift direction
// Load has priority over shifting.
module ShiftRegister_PIPO
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, left, load, clock,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
      if (left)
        Q <= {Q[WIDTH-2:0], 1'b0};
      else
        Q <= {1'b0, Q[WIDTH-1:1]};
        
endmodule : ShiftRegister_PIPO

// A SIPO Shift Register, with controllable shift direction
// Load has priority over shifting.
module ShiftRegister_SIPO
  #(parameter WIDTH=8)
  (input  logic             serial,
   input  logic             en, left, clock,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clock)
    if (en)
      if (left)
        Q <= {Q[WIDTH-2:0], serial};
      else
        Q <= {serial, Q[WIDTH-1:1]};
        
endmodule : ShiftRegister_SIPO

// A BSR shifts bits to the left by a variable amount
module BarrelShiftRegister
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, load, clock,
   input  logic [      1:0] by,
   output logic [WIDTH-1:0] Q);
   
  logic [WIDTH-1:0] shifted;
  always_comb
    case (by)
      default: shifted = Q;
      2'b01: shifted = {Q[WIDTH-2:0], 1'b0};
      2'b10: shifted = {Q[WIDTH-3:0], 2'b0};
      2'b11: shifted = {Q[WIDTH-4:0], 3'b0};
    endcase
   
  always_ff @(posedge clock)
    if (load)
        Q <= D;
    else if (en)
        Q <= shifted;
    
endmodule : BarrelShiftRegister


// Personal Custom block of counter with custome inc steps
module IncCounter
  #(parameter WIDTH=8)
  (input logic [WIDTH-1:0] step, 
   input logic [WIDTH-1:0] D,
   input logic en, clear, load, clock, up,
   output logic [WIDTH-1:0] Q);
  always_ff @(posedge clock) begin
    if (clear)
      Q <= {WIDTH {1'b0}};
    else if (load)
      Q <= D;
    else if (en)
      if (up)
        Q <= Q + step;
      else
        Q <= Q - step;
  end
    
endmodule


// Custom Shift Register with asymmetric input-output widths
module AsymmetricShiftRegister_PISO
  #(parameter INPUT_WIDTH = 32,
    parameter OUTPUT_WIDTH = 8)
  (input logic [INPUT_WIDTH-1 : 0] D,
   input logic en, load, left, clock,
   output logic [OUTPUT_WIDTH-1 : 0] Q);
  logic [INPUT_WIDTH-1 : 0] Buffer;

  always_comb begin
    if (left)
      Q = Buffer[INPUT_WIDTH - OUTPUT_WIDTH +: OUTPUT_WIDTH];
    else 
      Q = Buffer[0 +: OUTPUT_WIDTH];
  end

  always_ff @(posedge clock) begin
    if (load)
      Buffer <= D;
    else if (en)
      if (left) 
        Buffer <= {Buffer[0 +: INPUT_WIDTH - OUTPUT_WIDTH], {OUTPUT_WIDTH {1'b0}}};
      else
        Buffer <= {{OUTPUT_WIDTH {1'b0}}, Buffer[OUTPUT_WIDTH +: INPUT_WIDTH - OUTPUT_WIDTH]};
  end

endmodule

module AsymmetricShiftRegister_SIPO
  #(parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = 32)
  (input logic [INPUT_WIDTH-1 : 0] D, 
   input logic en, left, clock,
   output logic [OUTPUT_WIDTH-1 : 0] Q);
  
  always_ff @(posedge clock) begin
    if (en) begin
      if (left) 
        Q <= {Q[0 +: OUTPUT_WIDTH - INPUT_WIDTH], D};
      else
        Q <= {D, Q[INPUT_WIDTH +: OUTPUT_WIDTH - INPUT_WIDTH]};
    end
  end

endmodule

/*
 *  Create a FIFO (First In First Out) buffer with depth 4 using the given
 *  interface and constraints
 *    - The buffer is initally empty
 *    - Reads are combinational, so data_out is valid unless empty is asserted
 *    - Removal from the queue is processed on the clock edge.
 *    - Writes are processed on the clock edge
 *    - If a write is pending while the buffer is full, do nothing
 *    - If a read is pending while the buffer is empty, do nothing
 */
module FIFO #(parameter WIDTH=32) (
  input logic              clock, reset_n,
  input logic [WIDTH-1:0]  data_in,
  input logic              we, re,
  output logic [WIDTH-1:0] data_out,
  output logic             full, empty);
  logic [31:0] Q[4];
  logic [1:0] putPtr, getPtr; 
  logic [2:0] count;

  assign empty = (count == 0);
  assign full = (count == 3'd4);
  assign data_out = empty ? {WIDTH {1'bz}} : Q[getPtr];
  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) begin
      count <= 0;
      getPtr <= 0;
      putPtr <= 0;
    end
    else begin
      if (re && (!empty) && we) begin // read & write at the same time
        getPtr <= getPtr + 1;
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        count <= count;
      end
      else 
      if (re && (!empty)) begin // not empty
        getPtr <= getPtr + 1;
        count <= count - 1;
      end
      else if (we && (!full)) begin // not full
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        count <= count + 1;
      end
    end
  end
endmodule : FIFO