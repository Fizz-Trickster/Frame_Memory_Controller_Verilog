module SPSRAM                                   #(
parameter     DATA_WIDTH = 24,
parameter     ADDR_DEPTH = 1080*2400,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH)   )(  

  input   logic                   CLK   ,
  input   logic                   CSN   ,
  input   logic                   WEN   ,
  input   logic [ADDR_WIDTH-1:0]  ADDR  ,
  input   logic [DATA_WIDTH-1:0]  DIN   ,
  output  logic [DATA_WIDTH-1:0]  DOUT  
);

logic [DATA_WIDTH-1:0] MEM [0:ADDR_DEPTH];

// SRAM WRITE 
always_ff @(posedge CLK) begin
  if(!CSN & !WEN)
    MEM[ADDR] <= DIN;
end

// SRAM READ
always_ff @(posedge CLK) begin
  if(!CSN & WEN)
    DOUT <= #1 MEM[ADDR] ;
end

endmodule