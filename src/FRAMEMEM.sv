module FRAMEMEM                                   #(
parameter     DATA_WIDTH = 96,
parameter     ADDR_DEPTH = 512*512/4,
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

initial begin
  write_MEM_init;

  $display("MEM[0] : %h", MEM[0]); 
  $display("MEM[1] : %h", MEM[1]); 
  
end

task write_MEM_init;
begin
  logic [DATA_WIDTH/4-1:0]  IMAGE [0:ADDR_DEPTH*4];
  logic [ 7:0]              data_R  ;
  logic [ 7:0]              data_G  ;
  logic [ 7:0]              data_B  ;
  logic [23:0]              pixData ;

  int     fp;

  string  PPMHEADER_IDENTIFIER;
  int     PPMHEADER_HRES;
  int     PPMHEADER_VRES;
  int     PPMHEADER_MAXVALUE;

  fp = $fopen("24bpp-320x240.ppm", "r");
  
  $fscanf(fp, "%s\n",    PPMHEADER_IDENTIFIER);
  $fscanf(fp, "%d %d\n", PPMHEADER_HRES, PPMHEADER_VRES);
  $fscanf(fp, "%d\n",    PPMHEADER_MAXVALUE);

  for (int i=0;i<PPMHEADER_HRES*PPMHEADER_VRES;i++) begin
    $fscanf(fp, "%d %d %d\n", data_R, data_G, data_B);
    pixData = {data_R, data_G, data_B};
    IMAGE[i] = pixData;
  end

  for (int rowCnt=0;rowCnt<PPMHEADER_VRES/2;rowCnt++) begin
    for (int colCnt=0;colCnt<PPMHEADER_VRES/2;colCnt++) begin
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*3+:24] = IMAGE[(rowCnt*2+0)*PPMHEADER_HRES+(colCnt*2+0)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*2+:24] = IMAGE[(rowCnt*2+0)*PPMHEADER_HRES+(colCnt*2+1)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*1+:24] = IMAGE[(rowCnt*2+1)*PPMHEADER_HRES+(colCnt*2+0)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*0+:24] = IMAGE[(rowCnt*2+1)*PPMHEADER_HRES+(colCnt*2+1)];
    end
  end

  $display("IMAGE[0] : %h, [1] : %h, [2] : %h, [3] : %h",IMAGE[0], IMAGE[1], IMAGE[2], IMAGE[3]); 
  $fclose(fp);
end
endtask

endmodule