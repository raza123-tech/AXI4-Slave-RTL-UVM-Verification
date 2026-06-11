module axi_slave_phase1
(
    input  logic        ACLK,
    input  logic        ARESETN,

   
    input  logic [31:0] AWADDR,
    input  logic [7:0]  AWLEN,
    input  logic [2:0]  AWSIZE,
    input  logic [1:0]  AWBURST,
    input  logic        AWVALID,
    output logic        AWREADY,

   
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WLAST,
    input  logic        WVALID,
    output logic        WREADY,

   
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

  
    input  logic [31:0] ARADDR,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,
    input  logic [1:0]  ARBURST,
    input  logic        ARVALID,
    output logic        ARREADY,

    
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RLAST,
    output logic        RVALID,
    input  logic        RREADY
);

 
  // MEMORY
 

  logic [31:0] mem [0:255];

 

  logic [31:0] wr_addr;
logic [7:0]  wr_count;
logic [2:0]  wr_size;
logic [1:0]  wr_burst;

logic write_active;
logic addr_latched;

wire addr_active_comb =
     (AWVALID && AWREADY) ||
      addr_latched;

logic [31:0] rd_addr;
logic [7:0]  rd_count;
logic [2:0]  rd_size;
logic [1:0]  rd_burst;

logic read_active;

wire rd_active_comb =
     (ARVALID && ARREADY) ||
      read_active;

 
 
 
always_ff @(posedge ACLK or negedge ARESETN)
begin

  if(!ARESETN)
  begin

    AWREADY      <= 0;
    WREADY       <= 0;
    BVALID       <= 0;
    BRESP        <= 2'b00;

    write_active <= 0;

    wr_addr      <= 0;
    wr_count     <= 0;
    wr_size      <= 0;
    wr_burst     <= 0;

  end

  else
  begin

    AWREADY <= 0;
    WREADY  <= 0;

   




if(AWVALID && !write_active && !BVALID)
begin

  AWREADY <= 1;

  wr_addr  <= AWADDR;
  wr_count <= AWLEN;
  wr_size  <= AWSIZE;
  wr_burst <= AWBURST;

  write_active <= 1;

end
else
begin

  AWREADY <= 0;

end
    
   
  

    if(write_active)
    begin

      WREADY <= 1;
 if(WVALID && WREADY)
  begin

        $display(
          "WRITE Addr=%0d Data=%0d",
          wr_addr[9:2],
          WDATA
        );

        if(WSTRB[0])
          mem[wr_addr[9:2]][7:0] <= WDATA[7:0];

        if(WSTRB[1])
          mem[wr_addr[9:2]][15:8] <= WDATA[15:8];

        if(WSTRB[2])
          mem[wr_addr[9:2]][23:16] <= WDATA[23:16];

        if(WSTRB[3])
          mem[wr_addr[9:2]][31:24] <= WDATA[31:24];

        if(WLAST)
        begin

          BRESP <= 2'b00; /// okay
          BVALID <= 1;

          write_active <= 0;

        end

        else
        begin

          if(wr_burst == 2'b01)
            wr_addr <= wr_addr + (1 << wr_size);

          wr_count <= wr_count - 1;

        end

      end

    end

    

  

    if(BVALID && BREADY)
      BVALID <= 0;

  end

end

  

  always_ff @(posedge ACLK or negedge ARESETN)
  begin
    if (!ARESETN) begin
      ARREADY    <= 0;
      RVALID     <= 0;
      RLAST      <= 0;
      RRESP      <= 2'b00;
      RDATA      <= 0;
      read_active <= 0;
      rd_addr    <= 0;
      rd_count   <= 0;
      rd_size    <= 0;
      rd_burst   <= 0;
    end
    else begin

      ARREADY <= 0;


if(ARVALID && !read_active)
begin

  ARREADY <= 1;

  rd_addr     <= ARADDR;
  rd_count    <= ARLEN;
  rd_size     <= ARSIZE;
  rd_burst    <= ARBURST;

  read_active <= 1;

end
else
begin

  ARREADY <= 0;

end
    
if(read_active)
begin

  if(!RVALID)
  begin

    RVALID <= 1;
    RRESP  <= 2'b00;
    
    $display(
  "RVALID=%0b RREADY=%0b ADDR=%0d DATA=%0d",
  RVALID,
  RREADY,
  rd_addr[9:2],
  mem[rd_addr[9:2]]
);
    

    RDATA <= mem[rd_addr[9:2]];

    RLAST <= (rd_count == 0);

  end

  else if(RVALID && RREADY) 
  begin

    if(rd_count != 0)
    begin

      if(rd_burst == 2'b01)
        rd_addr <= rd_addr + (1<<rd_size);

      rd_count <= rd_count - 1;

      RDATA <= mem[(rd_addr + (1<<rd_size)) >> 2];

      RLAST <= (rd_count == 1);

    end

  end

end
      
      if (RVALID && RREADY && RLAST) begin
        RVALID      <= 0;
        RLAST       <= 0;
        read_active <= 0;
      end

    end
  end

endmodule
