module frame_memory_control                                   #(
parameter     DATA_WIDTH = 96,
parameter     ADDR_DEPTH = 512*512/4,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH),
parameter     FILE_PATH  = "24bpp-320x240.ppm"    )(  

  input   logic                   CLK   ,
  input   logic                   CSN   ,
  input   logic                   WEN   ,
  input   logic [ADDR_WIDTH-1:0]  ADDR  ,
  input   logic [DATA_WIDTH-1:0]  DIN   ,
  output  logic [DATA_WIDTH-1:0]  DOUT  
);

//memory_write_control #(
//
//) u_mem_wr_ctrl(
//
//);
//
//memory_read_control #(
//
//) u_mem_rd_ctrl (
//
//);
//FRAMEMEM #(
//
//) u_FRAMEMEM(
//
//);

endmodule