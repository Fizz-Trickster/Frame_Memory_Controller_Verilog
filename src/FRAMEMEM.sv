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
  write_MEM_initData;
  write_PPMFILE;  
end

task write_MEM_initData;
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
    for (int colCnt=0;colCnt<PPMHEADER_HRES/2;colCnt++) begin
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*3+:24] = IMAGE[(rowCnt*2+0)*PPMHEADER_HRES+(colCnt*2+0)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*2+:24] = IMAGE[(rowCnt*2+0)*PPMHEADER_HRES+(colCnt*2+1)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*1+:24] = IMAGE[(rowCnt*2+1)*PPMHEADER_HRES+(colCnt*2+0)];
      MEM[rowCnt*PPMHEADER_HRES/2+colCnt][24*0+:24] = IMAGE[(rowCnt*2+1)*PPMHEADER_HRES+(colCnt*2+1)];
    end
  end

  $fclose(fp);
end
endtask

task write_PPMFILE;
begin
  int     fp_in;
  int     fp_out;

  string  PPMHEADER_IDENTIFIER;
  int     PPMHEADER_HRES;
  int     PPMHEADER_VRES;
  int     PPMHEADER_MAXVALUE;
  
  int     addr;
  bit     isEvenRow;
  bit     isEvenCol;

  fp_in = $fopen("24bpp-320x240.ppm", "r");
  
  $fscanf(fp_in, "%s\n",    PPMHEADER_IDENTIFIER);
  $fscanf(fp_in, "%d %d\n", PPMHEADER_HRES, PPMHEADER_VRES);
  $fscanf(fp_in, "%d\n",    PPMHEADER_MAXVALUE);
  
  fp_out = $fopen("output.ppm", "w");
  $fdisplay(fp_out, "%s",       PPMHEADER_IDENTIFIER);
  $fdisplay(fp_out, "%0d %0d",  PPMHEADER_HRES, PPMHEADER_VRES);
  $fdisplay(fp_out, "%0d",      PPMHEADER_MAXVALUE);

  for (int rowCnt=0;rowCnt<PPMHEADER_VRES;rowCnt++) begin
    for (int colCnt=0;colCnt<PPMHEADER_HRES;colCnt++) begin
      addr      = (rowCnt/2) * (PPMHEADER_HRES/2) + (colCnt/2);
      isEvenRow = (rowCnt % 2 == 0);
      isEvenCol = (colCnt % 2 == 0);
      
      //$fwrite(fp_out, "addr :  %0d ", addr); 
      case ({isEvenRow, isEvenCol})
        2'b00 : $fdisplay(fp_out, "%0d %0d %0d", MEM[addr][24*0+2*8 +:8], MEM[addr][24*0+1*8 +:8], MEM[addr][24*0+0*8 +:8]);
        2'b01 : $fdisplay(fp_out, "%0d %0d %0d", MEM[addr][24*1+2*8 +:8], MEM[addr][24*1+1*8 +:8], MEM[addr][24*1+0*8 +:8]);
        2'b10 : $fdisplay(fp_out, "%0d %0d %0d", MEM[addr][24*2+2*8 +:8], MEM[addr][24*2+1*8 +:8], MEM[addr][24*2+0*8 +:8]);
        2'b11 : $fdisplay(fp_out, "%0d %0d %0d", MEM[addr][24*3+2*8 +:8], MEM[addr][24*3+1*8 +:8], MEM[addr][24*3+0*8 +:8]); 
      endcase
    end
  end

  $fclose(fp_in);
  $fclose(fp_out);
end
endtask

endmodule