import state_pkg::*;

module memory_read_control                        #(
parameter     DATA_WIDTH = 24,
parameter     MEM_WIDTH  = DATA_WIDTH*4,
parameter     ADDR_DEPTH = 512*512/4,
parameter     ADDR_WIDTH = $clog2(ADDR_DEPTH)     )(

  input   logic                   i_clk     ,
  input   logic                   rst_n     ,

  input   logic                   i_vsync   ,
  input   logic                   i_hsync   ,

  input   logic           [10:0]  i_PSC     ,
  input   logic           [10:0]  i_PEC     ,
  input   logic           [10:0]  i_SR      ,
  input   logic           [10:0]  i_ER      ,
  
  input   logic           [ 9:0]  i_vfp     ,
  input   logic           [ 3:0]  i_vpulse  ,
  input   logic           [ 9:0]  i_vbp     ,
  input   logic           [10:0]  i_vres    ,

  input   logic           [ 9:0]  i_hfp     ,
  input   logic           [ 3:0]  i_hpulse  ,
  input   logic           [ 9:0]  i_hbp     ,
  input   logic           [10:0]  i_hres    ,

  output  logic                   o_vsync   ,
  output  logic                   o_hsync   ,
  output  logic                   o_de      ,
  output  logic [DATA_WIDTH-1:0]  o_data    ,

  output  logic                   o_ren     ,
  output  logic [ADDR_WIDTH-1:0]  o_raddr   ,
  input   logic [ MEM_WIDTH-1:0]  i_rdata  
);

//========================================== 
// Internal Signal Description
//========================================== 
Vstate_t            cur_Vstate, nxt_Vstate;
Hstate_t            cur_Hstate, nxt_Hstate;

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
    S_HIDLE   : if(i_hsync              ) nxt_Hstate = S_HBP;              
    S_HPULSE  : if(colCnt == i_hpulse-1 ) nxt_Hstate = S_HBP;
    S_HBP     : if(colCnt == i_hbp-1    ) nxt_Hstate = S_HACTIVE;
    S_HACTIVE : if(colCnt == i_hres- 1  ) nxt_Hstate = S_HFP;
    S_HFP     : if(colCnt == i_hfp-1    ) nxt_Hstate = S_HPULSE;
  endcase
end

always_ff @(posedge i_clk, negedge rst_n ) begin
  if(~rst_n) begin
    colCnt <= 'd0;
  end else begin
    case(cur_Hstate)
      S_HIDLE   : colCnt <= colCnt;
      S_HPULSE  : begin
        if(colCnt == i_hpulse-1)  colCnt <= 'd0;
        else                      colCnt <= colCnt +'d1;
      end
      S_HBP     : begin
        if(colCnt == i_hbp-1)     colCnt <= 'd0;
        else                      colCnt <= colCnt +'d1;
      end
      S_HACTIVE : begin
        if(colCnt == i_hres-1)    colCnt <= 'd0;
        else                      colCnt <= colCnt +'d1;
      end
      S_HFP     : begin
        if(colCnt == i_hfp-1)     colCnt <= 'd0;
        else                      colCnt <= colCnt +'d1;
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
  //end else if(cur_Hstate == S_HPULSE && colCnt == 'd0) begin
  end else if(i_hsync) begin
    cur_Vstate  <= nxt_Vstate;
  end
end

//always @(*) begin
always_comb begin
  nxt_Vstate = cur_Vstate; // default 
  case (cur_Vstate)
    S_VIDLE   : if(i_vsync              ) nxt_Vstate = S_VPULSE;              
    S_VPULSE  : if(rowCnt == i_vpulse-1 ) nxt_Vstate = S_VBP;
    S_VBP     : if(rowCnt == i_vbp-1    ) nxt_Vstate = S_VACTIVE;
    S_VACTIVE : if(rowCnt == i_vres- 1  ) nxt_Vstate = S_VFP;
    S_VFP     : if(rowCnt == i_vfp-1    ) nxt_Vstate = S_VPULSE;
  endcase
end

always_ff @(posedge i_clk, negedge rst_n ) begin
  if(~rst_n) begin
    rowCnt <= 'd0;
  end else if(i_hsync) begin
    case(cur_Vstate)
      S_VIDLE   : rowCnt <= rowCnt;
      S_VPULSE  : begin
        if(rowCnt == i_vpulse-1)  rowCnt <= 'd0;
        else                      rowCnt <= rowCnt +'d1;
      end
      S_VBP     : begin
        if(rowCnt == i_vbp-1)     rowCnt <= 'd0;
        else                      rowCnt <= rowCnt +'d1;
      end
      S_VACTIVE : begin
        if(rowCnt == i_vres-1)    rowCnt <= 'd0;
        else                      rowCnt <= rowCnt +'d1;
      end
      S_VFP     : begin
        if(rowCnt == i_vfp-1)     rowCnt <= 'd0;
        else                      rowCnt <= rowCnt +'d1;
      end
    endcase
  end
end

//========================================== 
// Data Enable(de) 
//========================================== 
assign de = (cur_Hstate == S_HACTIVE) && (cur_Vstate == S_VACTIVE);

//========================================== 
// read control
// Frame Memory latency 3 clk 
//========================================== 
logic                 read_area; 
logic                 read_area_d; 
logic                 read_start; 
logic                 read_enable; 
logic [19:0]          read_addr;

logic [ MEM_WIDTH:0]  fmem_data;
logic [DATA_WIDTH:0]  data_out;

logic                 isEvenLine; 
logic                 isOddLine; 
logic                 isEvenPixel;
logic                 isOddPixel;

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    read_area <= 'd0; 
  end else if(cur_Vstate == S_VACTIVE && rowCnt >= i_SR && rowCnt <= i_ER) begin
    if(cur_Hstate == S_HBP && colCnt == 'd0) begin
      read_area <= 'd1; 
    end else if(cur_Hstate == S_HFP && colCnt == 'd0) begin
      read_area <= 'd0; 
    end
  end
end

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    read_area_d <= 'd0; 
  end else begin
    read_area_d <= read_area; 
  end
end

assign read_start = ({read_area,read_area_d} == 2'b10);

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin 
    read_addr <= 'd0; 
  end else if(read_start) begin
    read_addr <= i_hres*(rowCnt >> 1) + (i_PSC >> 1); 
  //end else if(read_area && isEvenLine) begin
  end else if(read_area) begin
    read_addr <= read_addr + 'd1; 
  end
end

assign isEvenLine   = (cur_Vstate == S_VACTIVE) && (~rowCnt[0]);
assign isOddLine    = (cur_Vstate == S_VACTIVE) && ( rowCnt[0]);

assign isEvenPixel  = (de) && (~colCnt[0]);
assign isOddPixel   = (de) && ( colCnt[0]);

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin
    read_enable <= 'd0; 
  //end else if(read_start && isEvenLine) begin
  end else if(read_start) begin
    read_enable <= 'd1; 
  end else if(read_addr == (i_hres*((rowCnt>>1)+1))-1) begin
    read_enable <= 'd0; 
  end
end

assign o_raddr  = read_addr >> 1;
assign o_ren    = ~(read_enable && ~read_addr[0]);

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin
    fmem_data <= 'd0; 
  end else if(read_enable && read_addr[0]) begin
    fmem_data <= i_rdata;
  end else if(~read_area) begin 
    fmem_data <= 'd0;
  end
end

always_comb begin
  data_out = 'd0; // default 
  case ({isEvenLine, isEvenPixel})
    {2'b00} : data_out = fmem_data[00+:24];              
    {2'b01} : data_out = fmem_data[24+:24];
    {2'b10} : data_out = fmem_data[48+:24];
    {2'b11} : data_out = fmem_data[72+:24];
  endcase
end

always_ff @(posedge i_clk, negedge rst_n) begin
  if(~rst_n) begin
    o_vsync <= 'd0; 
    o_hsync <= 'd0;
    o_de    <= 'd0;
    o_data  <= 'd0;
  end else begin
    o_vsync <= i_vsync  ; 
    o_hsync <= i_hsync  ;
    o_de    <= de       ;
    o_data  <= data_out ;
  end
end

endmodule