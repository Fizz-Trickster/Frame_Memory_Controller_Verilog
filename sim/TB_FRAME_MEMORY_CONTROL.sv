`timescale 1ns / 1ns

import state_pkg::*;

module TB_FRAME_MEMORY_CONTROL;

parameter   HRES        = 320;
parameter   VRES        = 240;
parameter   DATA_WIDTH  = 24;
parameter   MEM_WIDTH   = DATA_WIDTH*4;
parameter   ADDR_DEPTH  = HRES*VRES/4;
parameter   ADDR_WIDTH  = $clog2(ADDR_DEPTH);     

localparam  CLK_PERIOD  = 10;

bit                 clk;    // 2-state, default : 0
bit                 rst_n;

// Vstate, Hstate
Vstate_t            Vstate;
Hstate_t            Hstate;

// VSYNC, HSYNC, DE
logic               vsync;
logic               hsync;
logic               de;
logic        [23:0] data;

// Frame Memory Control
logic                   fmem_csn   ;
logic                   fmem_wen   ;
logic [ADDR_WIDTH-1:0]  fmem_addr  ;
logic [DATA_WIDTH-1:0]  fmem_din   ;
logic [DATA_WIDTH-1:0]  fmem_dout  ;

logic                   o_vsync    ;
logic                   o_hsync    ;
logic                   o_de       ;
logic [DATA_WIDTH-1:0]  o_data     ;

// Partial Display 
bit             [10:0]  PSC        ;
bit             [10:0]  PEC        ;
bit             [10:0]  SR         ;
bit             [10:0]  ER         ;

always #(CLK_PERIOD/2) clk = ~clk;

//initial begin
//  $dumpfile("dump.vcd");
//  $dumpvars;
//end

disp_sync_gen_fsm #(
  .VPULSE  (1),
  .HPULSE  (1),
  .VRES    (VRES),
  .HRES    (HRES),
  .VBP     (3),
  .VFP     (5),
  .HBP     (4),
  .HFP     (5)   
)   u_disp_sync_gen_fsm (
      .i_clk      (clk
  ),  .rst_n      (rst_n
  ),  .o_Vstate   (Vstate
  ),  .o_Hstate   (Hstate
  ),  .o_vsync    (vsync
  ),  .o_hsync    (hsync
  ),  .o_de       (de
  ));

frame_memory_control #(
  .DATA_WIDTH     (DATA_WIDTH),
  .ADDR_DEPTH     (ADDR_DEPTH),
  .FILE_PATH      ("24bpp-320x240.ppm")
) u_frame_mem_ctrl(
      .i_clk      (clk
  ),  .rst_n      (rst_n
  ),  .i_vsync    (vsync
  ),  .i_hsync    (hsync

  ),  .i_PSC      (PSC
  ),  .i_PEC      (PEC
  ),  .i_SR       (SR 
  ),  .i_ER       (ER 
  
  ),  .i_vbp      (3
  ),  .i_vpulse   (1
  ),  .i_vfp      (5
  ),  .i_vres     (VRES

  ),  .i_hbp      (4
  ),  .i_hpulse   (1
  ),  .i_hfp      (5
  ),  .i_hres     (HRES

  ),  .o_vsync    (o_vsync
  ),  .o_hsync    (o_hsync
  ),  .o_de       (o_de    
  ),  .o_data     (o_data 

  ));

PPM_FILE_WRITE_MODEL #(
  .DATA_WIDTH     (DATA_WIDTH),
  .HRES           (HRES),
  .VRES           (VRES)
) u_PPM_FILE_WRITE_MODEL(
      .clk             (clk
  ),  .rst_n           (rst_n

  ),  .i_vsync         (o_vsync
  ),  .i_hsync         (o_hsync
  ),  .i_de            (o_de    
  ),  .i_data          (o_data 
  ));

//FRAMEMEM #(
//  .DATA_WIDTH     ( MEM_WIDTH),
//  .ADDR_DEPTH     (ADDR_DEPTH),
//  .FILE_PATH      ("24bpp-320x240.ppm")
//) u_FRAMEMEM(
//      .CLK        (clk
//  ),  .CSN        (fmem_csn
//  ),  .WEN        (fmem_wen
//  ),  .ADDR       (fmem_addr
//  ),  .DIN        (fmem_din
//  ),  .DOUT       (fmem_dout
//  ));

initial begin
  #(CLK_PERIOD*3) rst_n   <= 'd1;
  
  PSC = 0;
  PEC = HRES-1;
  SR  = 10;
  ER  = VRES-1;
  
  repeat(3) @(posedge vsync);
  repeat(5) @(posedge clk);
  $finish;
end

endmodule