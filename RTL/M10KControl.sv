`default_nettype none

// Wrapper handling M10K read and write
module M10KControl
  (input logic read, write,
   input logic [7:0] address,
   input logic [31:0] writedata,
   output logic [31:0] readdata);

  logic write, chipselect;
  assign chipselect = read | write;

  M10K RAM(.byteenable(4'hF), .*);

endmodule: M10KControl

// Dummy M10K
module M10K
  (input logic write, chipselect,
   input logic [7:0] address,
   input logic [3:0] byteenable,
   input logic [31:0] writedata,
   output logic [31:0] readdata);

   assign readdata = 'd16;

endmodule: M10K


module fakemem
  (input logic read, write, clock, 
   input logic [`ADDR_WIDTH-1:0] address,
   input logic [`DATA_WIDTH-1:0] writedata,
   output logic [`DATA_WIDTH-1:0] readdata);

  logic [63:0][31:0] mem;

  always_comb begin
    mem[0] = {4'd1, 7'd8, 7'd12, 7'd8, 7'd12};
    // mem[1] = (5);
    // mem[9:2] = (0);
    // mem[10] = (1);
    // mem[11] = (2);
    // mem[12] = (3);
    // mem[13] = (4);
    // mem[14] = (5);
    // mem[29:15] = (0);
    // mem[30] = (10);
    // mem[31] = (12);
    // mem[32] = (14);
    // mem[33] = (16);
    // mem[63:34] = (0);
    mem[1] = $shortrealtobits(5);
    mem[9:2] = $shortrealtobits(0);
    mem[10] = $shortrealtobits(1);
    mem[11] = $shortrealtobits(2);
    mem[12] = $shortrealtobits(3);
    mem[13] = $shortrealtobits(4);
    mem[14] = $shortrealtobits(5);
    mem[15] = $shortrealtobits(6);
    mem[29:16] = $shortrealtobits(0);
    mem[30] = $shortrealtobits(10);
    mem[31] = $shortrealtobits(12);
    mem[32] = $shortrealtobits(14);
    mem[33] = $shortrealtobits(16);
    mem[34] = $shortrealtobits(18);
    mem[35] = $shortrealtobits(20);
    mem[63:36] = $shortrealtobits(0);
  end

  always_ff @(posedge clock) begin
    if (read) readdata <= mem[address];
    // else if (write) mem[address] <= writedata;
    else readdata <= 'b0;
  end

endmodule: fakemem