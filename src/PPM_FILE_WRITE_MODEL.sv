module PPM_FILE_WRITE_MODEL       #(
parameter     DATA_WIDTH  = 24, 
parameter     HRES        = 320, 
parameter     VRES        = 240   )(

  input   logic                 clk             ,
  input   logic                 rst_n           ,

  input   logic                 i_vsync         ,
  input   logic                 i_hsync         ,
  input   logic                 i_de            ,
  input   logic [DATA_WIDTH:0]  i_data          
);

int     fp;

// PPM FILE HEADER
string  PPMHEADER_IDENTIFIER  = "P3";
int     PPMHEADER_HRES        = HRES;
int     PPMHEADER_VRES        = VRES;
int     PPMHEADER_MAXVALUE    = 255;

// FILE OPEN
always @(negedge i_vsync) begin
  fp = $fopen("o_24bpp-320x240.ppm", "w");
  fwritePPMHEADER;
end

// FILE CLOSE
always @(posedge i_vsync) begin
  $fclose(fp);
end

// FILE Write
always @(posedge clk) begin
  if(i_de) begin
    $fdisplay(fp, "%0d %0d %0d", i_data[16+:8], i_data[8+:8], i_data[0+:8]);
  end
end

task fwritePPMHEADER;
begin
  $fdisplay(fp, "%s",    PPMHEADER_IDENTIFIER);
  $fdisplay(fp, "%0d %0d", PPMHEADER_HRES, PPMHEADER_VRES);
  $fdisplay(fp, "%0d",    PPMHEADER_MAXVALUE);
end
endtask

endmodule