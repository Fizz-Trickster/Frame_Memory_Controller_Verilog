`timescale 1ns / 1ns

import state_pkg::*;

module TB_FRAME_MEMORY_CONTROL;

parameter   HRES        = 320;
parameter   VRES        = 240;
parameter   DATA_WIDTH  = 96;
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

// VSYNC, HSYNC, DE
logic                   fmem_csn   ;
logic                   fmem_wen   ;
logic [ADDR_WIDTH-1:0]  fmem_addr  ;
logic [DATA_WIDTH-1:0]  fmem_din   ;
logic [DATA_WIDTH-1:0]  fmem_dout  ;


always #(CLK_PERIOD/2) clk = ~clk;

//initial begin
//  $dumpfile("dump.vcd");
//  $dumpvars;
//end

disp_sync_gen_fsm #(
  .VPULSE  (3),
  .HPULSE  (3),
  .VRES    (VRES),
  .HRES    (HRES),
  .VBP     (3),
  .VFP     (5),
  .HBP     (3),
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

FRAMEMEM #(
  .DATA_WIDTH     (DATA_WIDTH),
  .ADDR_DEPTH     (ADDR_DEPTH),
  .FILE_PATH      ("24bpp-320x240.ppm")
) u_FRAMEMEM(
      .CLK        (clk
  ),  .CSN        (fmem_csn
  ),  .WEN        (fmem_wen
  ),  .ADDR       (fmem_addr
  ),  .DIN        (fmem_din
  ),  .DOUT       (fmem_dout
  ));

initial begin
  #(CLK_PERIOD*3) rst_n   <= 'd1;

  repeat(3) @(posedge vsync);
  repeat(5) @(posedge clk);
  $finish;
end

endmodule