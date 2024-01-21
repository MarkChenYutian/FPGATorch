`default_nettype none


module fakemem_read
  (input logic read, write, clock, 
   input logic [`ADDR_WIDTH-1:0] addr,
   output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] data);

  logic [511:0][31:0] mem;

  assign mem[63:0] = {$shortrealtobits(3), $shortrealtobits(9), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(7), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(3), $shortrealtobits(3), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(2), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(6), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(6), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(5)};
  assign mem[133:70] = {$shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(2), $shortrealtobits(6), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(6), $shortrealtobits(5), $shortrealtobits(5), $shortrealtobits(8), $shortrealtobits(4), $shortrealtobits(8), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(1), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(2), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(7), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(6), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(4), $shortrealtobits(9), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(7), $shortrealtobits(7), $shortrealtobits(8), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(8), $shortrealtobits(5), $shortrealtobits(2), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(1), $shortrealtobits(5), $shortrealtobits(1), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(4), $shortrealtobits(1), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(2), $shortrealtobits(8), $shortrealtobits(3), $shortrealtobits(7), $shortrealtobits(1), $shortrealtobits(9), $shortrealtobits(9), $shortrealtobits(3), $shortrealtobits(2), $shortrealtobits(4)};

  always_ff @(posedge clock) begin
    if (read) data <= {mem[addr+7], mem[addr+6], mem[addr+5], mem[addr+4],
                       mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    else data <= 'b0;
  end

endmodule: fakemem_read


module fakemem_write
  (input logic read, write, clock, 
   input logic [`ADDR_WIDTH-1:0] addr,
   output logic [`BANDWIDTH-1:0][`DATA_WIDTH-1:0] data);

  logic [511:0][31:0] mem;

  always_ff @(posedge clock) begin
    if (write) {mem[addr+7], mem[addr+6], mem[addr+5], mem[addr+4],
                mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= data;
    else data <= 'b0;
  end

endmodule: fakemem_write


module fakemem
  (input logic read, write, clock, 
   input logic [`ADDR_WIDTH-1:0] address,
   input logic [`DATA_WIDTH*`BANDWIDTH-1:0] writedata,
   output logic [`DATA_WIDTH*`BANDWIDTH-1:0] readdata);

  logic [63:0][255:0] mem;

  always_comb begin
    mem[0] = {MAT_SCAL_MUL, 7'd16, 7'd12, 7'd16, 7'd12};
    mem[1] = $shortrealtobits(5);
    mem[9:2] = $shortrealtobits(0);
    mem[10] = {$shortrealtobits(32'd1), $shortrealtobits(32'd17), $shortrealtobits(32'd18), $shortrealtobits(32'd19)};
    mem[11] = {$shortrealtobits(32'd2), $shortrealtobits(32'd27), $shortrealtobits(32'd28), $shortrealtobits(32'd29)};
    mem[12] = {$shortrealtobits(32'd3), $shortrealtobits(32'd37), $shortrealtobits(32'd38), $shortrealtobits(32'd39)};
    mem[13] = $shortrealtobits(4);
    mem[14] = $shortrealtobits(5);
    mem[15] = $shortrealtobits(6);
    mem[16] = $shortrealtobits(1);
    mem[17] = $shortrealtobits(2);
    mem[18] = $shortrealtobits(3);
    mem[19] = $shortrealtobits(4);
    mem[20] = $shortrealtobits(5);
    mem[21] = $shortrealtobits(6);
    mem[29:22] = $shortrealtobits(0);
    mem[30] = $shortrealtobits(10);
    mem[31] = $shortrealtobits(12);
    mem[32] = $shortrealtobits(14);
    mem[33] = $shortrealtobits(16);
    mem[34] = $shortrealtobits(18);
    mem[35] = $shortrealtobits(20);
    mem[36] = $shortrealtobits(10);
    mem[37] = $shortrealtobits(12);
    mem[38] = $shortrealtobits(14);
    mem[39] = $shortrealtobits(16);
    mem[40] = $shortrealtobits(18);
    mem[41] = $shortrealtobits(20);
    mem[63:42] = $shortrealtobits(0);
  end

  always_ff @(posedge clock) begin
    if (read) readdata <= mem[address];
    // else if (write) mem[address] <= writedata;
    else readdata <= 'b0;
  end

endmodule: fakemem