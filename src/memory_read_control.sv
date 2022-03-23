module memory_read_control                        #(
parameter     DATA_WIDTH = 96,
parameter     ADDR_DEPTH = 512*512/4,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH)     )(

  input   logic                   clk       ,

  input   logic                   i_vsync   ,
  input   logic                   i_hsync   ,
  input   logic           [ 9:0]  i_vfp     ,
  input   logic           [ 9:0]  i_vbp     ,
  input   logic           [ 9:0]  i_hfp     ,
  input   logic           [ 9:0]  i_hbp     ,

  input   logic           [10:0]  i_vres    ,
  input   logic           [10:0]  i_hres    ,
  
  output  logic                   o_ren     ,
  output  logic [ADDR_WIDTH-1:0]  o_raddr   ,
  input   logic [DATA_WIDTH-1:0]  i_rdata  
);

endmodule