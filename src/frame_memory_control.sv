module frame_memory_control                                   #(
parameter     DATA_WIDTH = 24,
parameter     MEM_WIDTH  = DATA_WIDTH*4,
parameter     ADDR_DEPTH = 512*512/4,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH),
parameter     FILE_PATH  = "24bpp-320x240.ppm"    )(  

  input   logic                   i_clk     ,
  input   logic                   rst_n     ,

  input   logic                   i_vsync   ,
  input   logic                   i_hsync   ,
  input   logic           [ 9:0]  i_vfp     ,
  input   logic           [ 9:0]  i_vbp     ,
  input   logic           [ 9:0]  i_hfp     ,
  input   logic           [ 9:0]  i_hbp     ,

  input   logic           [10:0]  i_vres    ,
  input   logic           [10:0]  i_hres    ,

  output  logic                   o_vsync   ,
  output  logic                   o_hsync   ,
  output  logic [DATA_WIDTH-1:0]  o_data    ,
  output  logic                   o_de    
);

// Frame Memory Control
logic                   fmem_csn   ;
logic                   fmem_wen   ;
logic [ADDR_WIDTH-1:0]  fmem_addr  ;
logic [ MEM_WIDTH-1:0]  fmem_din   ;
logic [ MEM_WIDTH-1:0]  fmem_dout  ;

//memory_write_control #(
//
//) u_mem_wr_ctrl(
//
//);
//

memory_read_control #(
  .DATA_WIDTH     (DATA_WIDTH), 
  .ADDR_DEPTH     (ADDR_DEPTH) 
) u_mem_rd_ctrl (
      .i_clk      (i_clk
  ),  .rst_n      (rst_n

  ),  .i_vsync    (i_vsync
  ),  .i_hsync    (i_hsync
  ),  .i_vfp      (i_vfp  
  ),  .i_vbp      (i_vbp  
  ),  .i_hfp      (i_hfp  
  ),  .i_hbp      (i_hbp  

  ),  .i_vres     (i_vres 
  ),  .i_hres     (i_hres 

  ),  .o_ren      ( 
  ),  .o_raddr    ( 
  ),  .i_rdata    ('d0 
  ));

FRAMEMEM #(
  .DATA_WIDTH     ( MEM_WIDTH),
  .ADDR_DEPTH     (ADDR_DEPTH),
  .FILE_PATH      (FILE_PATH )
) u_FRAMEMEM(
      .CLK        (clk
  ),  .CSN        (fmem_csn
  ),  .WEN        (fmem_wen
  ),  .ADDR       (fmem_addr
  ),  .DIN        (fmem_din
  ),  .DOUT       (fmem_dout
  ));

endmodule