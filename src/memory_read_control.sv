import state_pkg::*;

module memory_read_control                        #(
parameter     DATA_WIDTH = 24,
parameter     ADDR_DEPTH = 512*512/4,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH)     )(

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
  
  output  logic                   o_ren     ,
  output  logic [ADDR_WIDTH-1:0]  o_raddr   ,
  input   logic [DATA_WIDTH-1:0]  i_rdata  
);

//========================================== 
// Internal Signal Description
//========================================== 
Vstate_t            cur_Vstate, nxt_Vstate;
Hstate_t            cur_Hstate, nxt_Hstate;
Vstate_t  [ 2:0]    cur_Vstate_d;
Hstate_t  [ 2:0]    cur_Hstate_d;

logic     [11:0]    colCnt;
logic     [11:0]    rowCnt;

logic               de;

//========================================== 
// column count
//========================================== 
always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    cur_Hstate  <= S_HIDLE;
  end else begin
    cur_Hstate  <= nxt_Hstate;
  end
end

//always @(*) begin
always_comb begin
  nxt_Hstate = cur_Hstate; // default 
  case (cur_Hstate)
    S_HIDLE   : if(rst_n              ) nxt_Hstate = S_HPULSE;              
    S_HPULSE  : if(colCnt == 1-1      ) nxt_Hstate = S_HBP;
    S_HBP     : if(colCnt == i_hbp-1  ) nxt_Hstate = S_HACTIVE;
    S_HACTIVE : if(colCnt == i_hres- 1) nxt_Hstate = S_HFP;
    S_HFP     : if(colCnt == i_hfp-1  ) nxt_Hstate = S_HPULSE;
  endcase
end

always_ff @(posedge i_clk, negedge rst_n ) begin
  if(~rst_n) begin
    colCnt <= 'd0;
  end else begin
    case(cur_Hstate)
      S_HIDLE   : colCnt <= colCnt;
      S_HPULSE  : begin
        if(colCnt == 1-1)       colCnt <= 'd0;
        else                    colCnt <= colCnt +'d1;
      end
      S_HBP     : begin
        if(colCnt == i_hbp-1)   colCnt <= 'd0;
        else                    colCnt <= colCnt +'d1;
      end
      S_HACTIVE : begin
        if(colCnt == i_hres-1)  colCnt <= 'd0;
        else                    colCnt <= colCnt +'d1;
      end
      S_HFP     : begin
        if(colCnt == i_hfp-1)   colCnt <= 'd0;
        else                    colCnt <= colCnt +'d1;
      end
    endcase
  end
end

//========================================== 
// row count 
//========================================== 
always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    cur_Vstate  <= S_VIDLE;
  end else if(cur_Hstate == S_HPULSE && colCnt == 'd0) begin
    cur_Vstate  <= nxt_Vstate;
  end
end

//always @(*) begin
always_comb begin
  nxt_Vstate = cur_Vstate; // default 
  case (cur_Vstate)
    S_VIDLE   : if(rst_n              ) nxt_Vstate = S_VPULSE;              
    S_VPULSE  : if(rowCnt == 1-1      ) nxt_Vstate = S_VBP;
    S_VBP     : if(rowCnt == i_vbp-1  ) nxt_Vstate = S_VACTIVE;
    S_VACTIVE : if(rowCnt == i_vres- 1) nxt_Vstate = S_VFP;
    S_VFP     : if(rowCnt == i_vfp-1  ) nxt_Vstate = S_VPULSE;
  endcase
end

always_ff @(posedge i_clk, negedge rst_n ) begin
  if(~rst_n) begin
    rowCnt <= 'd0;
  end else if(cur_Hstate == S_HPULSE && colCnt == 'd0) begin
    case(cur_Vstate)
      S_VIDLE   : rowCnt <= rowCnt;
      S_VPULSE  : begin
        if(rowCnt == 1-1)       rowCnt <= 'd0;
        else                    rowCnt <= rowCnt +'d1;
      end
      S_VBP     : begin
        if(rowCnt == i_vbp-1)   rowCnt <= 'd0;
        else                    rowCnt <= rowCnt +'d1;
      end
      S_VACTIVE : begin
        if(rowCnt == i_vres-1)  rowCnt <= 'd0;
        else                    rowCnt <= rowCnt +'d1;
      end
      S_VFP     : begin
        if(rowCnt == i_vfp-1)   rowCnt <= 'd0;
        else                    rowCnt <= rowCnt +'d1;
      end
    endcase
  end
end

//========================================== 
// Data Enable(de) 
//========================================== 
always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    cur_Hstate_d  <= 'd0;
    cur_Vstate_d  <= 'd0;
  end else begin
    cur_Vstate_d  <= {cur_Vstate_d[1:0], cur_Vstate};
    cur_Hstate_d  <= {cur_Hstate_d[1:0], cur_Hstate};
  end
end

assign de = (cur_Hstate_d[1] == S_HACTIVE) && (cur_Vstate_d[0] == S_VACTIVE);

//========================================== 
// read control 
//========================================== 
logic         read_enable; 
logic [14:0]  addr;

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    read_enable <= 'd0; 
  end else if(cur_Vstate_d[0] == S_VACTIVE) begin
    if(cur_Hstate_d[1] == S_HBP && colCnt == 'd0) begin
      read_enable <= 'd1; 
    end else if(cur_Hstate_d[1] == S_HFP && colCnt == 'd0) begin
      read_enable <= 'd0; 
    end
  end
end

endmodule