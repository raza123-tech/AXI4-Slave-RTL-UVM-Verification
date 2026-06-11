
`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"


interface axi_if;

  logic        ACLK;
  logic        ARESETN;

    logic [31:0] AWADDR;
  logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
  logic [1:0]  AWBURST;
  logic        AWVALID;
  logic        AWREADY;

  logic [31:0] WDATA;
  logic [3:0]  WSTRB;
  logic        WLAST;
  logic        WVALID;
  logic        WREADY;

  logic [1:0]  BRESP;
  logic        BVALID;
  logic        BREADY;

  logic [31:0] ARADDR;
  logic [7:0]  ARLEN;
      logic [2:0]  ARSIZE;
  logic [1:0]  ARBURST;
    logic        ARVALID;
  logic        ARREADY;

  logic [31:0] RDATA;
  logic [1:0]  RRESP;
  logic        RLAST;
    logic        RVALID;
  logic        RREADY;

  
  // ASSERTIONS


  property p_awvalid_awready;
    @(posedge ACLK) disable iff(!ARESETN)
    AWVALID |-> ##[0:10] AWREADY;
  endproperty
  assert property(p_awvalid_awready);

  property p_wvalid_wready;
    @(posedge ACLK) disable iff(!ARESETN)
    WVALID |-> ##[0:10] WREADY;
  endproperty
  assert property(p_wvalid_wready);
  
  property p_bvalid_bready;
    @(posedge ACLK) disable iff(!ARESETN)
    BVALID |-> ##[0:10] BREADY;
  endproperty
  assert property(p_bvalid_bready);

  property p_arvalid_arready;
    @(posedge ACLK) disable iff(!ARESETN)
      ARVALID |-> ##[0:10] ARREADY;
  endproperty
  assert property(p_arvalid_arready);

    property p_rvalid_rready;
    @(posedge ACLK) disable iff(!ARESETN)
    RVALID |-> ##[0:10] RREADY;
  endproperty
  assert property(p_rvalid_rready);

    property p_wlast_valid;
    @(posedge ACLK) disable iff(!ARESETN)
    WLAST |-> WVALID;
  endproperty
  assert property(p_wlast_valid);

  property p_rlast_valid;
    @(posedge ACLK) disable iff(!ARESETN)
    RLAST |-> RVALID;
  endproperty
  assert property(p_rlast_valid);

endinterface



// TRANSACTION


class axi_transaction extends uvm_sequence_item;

  rand bit        write;
  rand bit        read;
  rand bit [31:0] addr;
    rand bit [7:0]  len;
  rand bit [2:0]  size;
  rand bit [1:0]  burst;
  rand bit [31:0] data[];
    rand bit [3:0]  strb[];
       bit [31:0] rdata[];

    constraint c_rw    { write != read; }
  constraint c_len   { len inside {[0:15]}; }
  constraint c_array { data.size() == len + 1; strb.size() == len + 1; }

  `uvm_object_utils(axi_transaction)

  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

    function string convert2string();
    return $sformatf(
      "write=%0d read=%0d addr=0x%0h len=%0d size=%0d burst=%0d",
      write, read, addr, len, size, burst
    );
  endfunction

endclass



// SEQUENCES


class axi_write_burst_seq extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_write_burst_seq)

  function new(string name = "axi_write_burst_seq");
    super.new(name);
  endfunction

  task body();
    axi_transaction tx;
    tx = axi_transaction::type_id::create("tx");
    start_item(tx);

      tx.write   = 1;
    tx.read    = 0;
    tx.addr    = 32'h0000_0000;
    tx.len     = 3;
      tx.size    = 3'b010;
    tx.burst   = 2'b01;
    tx.data    = new[4];
    tx.strb    = new[4];
    tx.data[0] = 10; tx.data[1] = 11; tx.data[2] = 12; tx.data[3] = 13;
      foreach(tx.strb[i]) tx.strb[i] = 4'b1111;

    finish_item(tx);
  endtask

endclass


class axi_read_burst_seq extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_read_burst_seq)

  function new(string name = "axi_read_burst_seq");
    super.new(name);
  endfunction

  task body();
    axi_transaction tx;
    tx = axi_transaction::type_id::create("tx");
    start_item(tx);

    tx.write  = 0;
    tx.read   = 1;
        tx.addr   = 32'h0000_0000;
    tx.len    = 3;
    tx.size   = 3'b010;
    tx.burst  = 2'b01;
      tx.rdata  = new[tx.len + 1];

    finish_item(tx);
  endtask

endclass



// SEQUENCER

class axi_sequencer extends uvm_sequencer #(axi_transaction);
  `uvm_component_utils(axi_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass



// DRIVER


class axi_driver extends uvm_driver #(axi_transaction);

  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axi_if)::get(this,"","vif",vif))
      `uvm_fatal("DRV","VIRTUAL INTERFACE NOT FOUND")
  endfunction

  task run_phase(uvm_phase phase);
    axi_transaction tx;
    // Initialise all outputs to safe values before reset releases
    vif.AWVALID <= 0; vif.WVALID <= 0; vif.BREADY <= 0;
    vif.ARVALID <= 0; vif.RREADY <= 0;
    vif.WDATA   <= 0; vif.WSTRB  <= 0; vif.WLAST  <= 0;
      forever begin
      seq_item_port.get_next_item(tx);
      if(tx.write) drive_write(tx);
      if(tx.read)  drive_read(tx);
        seq_item_port.item_done();
    end
  endtask

  
 
 
  task drive_write(axi_transaction tx);

    
    @(posedge vif.ACLK);
    vif.AWADDR  <= tx.addr;
        vif.AWLEN   <= tx.len;
      vif.AWSIZE  <= tx.size;
    vif.AWBURST <= tx.burst;
    vif.AWVALID <= 1;

    @(posedge vif.ACLK);
    while(!vif.AWREADY) @(posedge vif.ACLK);
    vif.AWVALID <= 0;

  foreach(tx.data[i])
begin

  @(posedge vif.ACLK);

  vif.WDATA  <= tx.data[i];
  vif.WSTRB  <= tx.strb[i];
    vif.WLAST  <= (i == tx.len);
  vif.WVALID <= 1;

  do
    @(posedge vif.ACLK);
  while(!vif.WREADY);

  `uvm_info(
    "DRV_WRITE",
    $sformatf(
      "Beat=%0d Data=%0d",
      i,
      tx.data[i]
    ),
    UVM_LOW
  );

  vif.WVALID <= 0;

end

vif.WLAST <= 0;

    `uvm_info("DRV_WRITE","ALL WRITE BEATS SENT", UVM_LOW)

    
    vif.BREADY <= 1;
    @(posedge vif.ACLK);
    while(!vif.BVALID) @(posedge vif.ACLK);
    `uvm_info("WRITE_RESP", $sformatf("BRESP=%0d", vif.BRESP), UVM_LOW)
    @(posedge vif.ACLK);
    vif.BREADY <= 0;

  endtask

  
  task drive_read(axi_transaction tx);

      @(posedge vif.ACLK);
    vif.ARADDR  <= tx.addr;
    vif.ARLEN   <= tx.len;
    vif.ARSIZE  <= tx.size;
      vif.ARBURST <= tx.burst;
    vif.ARVALID <= 1;

    @(posedge vif.ACLK);
    while(!vif.ARREADY) @(posedge vif.ACLK);
    vif.ARVALID <= 0;

    vif.RREADY <= 1; 
    forever begin
      @(posedge vif.ACLK);
        if(vif.RVALID) begin  
        `uvm_info("READ_DATA",
          $sformatf("RDATA=%0d", vif.RDATA), UVM_LOW)
        if(vif.RLAST) break;
      end
    end
    vif.RREADY <= 0;

  endtask

endclass



// MONITOR


class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  uvm_analysis_port #(axi_transaction) mon_ap;

  
 
 

  function new(
    string name,
    uvm_component parent
  );
    super.new(name,parent);

    mon_ap = new(
      "mon_ap",
      this
    );
  endfunction

  
  
 

  function void build_phase(
    uvm_phase phase
  );

    super.build_phase(phase);

    if(!uvm_config_db#
      (virtual axi_if)
      ::get(this,"","vif",vif))
    begin

      `uvm_fatal(
        "MON",
        "VIRTUAL INTERFACE NOT FOUND"
      )

    end

  endfunction

  

  task run_phase(
    uvm_phase phase
  );

    fork
      forever monitor_write();
      forever monitor_read();
    join

  endtask

  

  task monitor_write();

    axi_transaction tx;

    @(posedge vif.ACLK);

    if(vif.AWVALID && vif.AWREADY)
    begin

      tx =
      axi_transaction::
      type_id::
      create("wr_tx");

      tx.write = 1;
      tx.read  = 0;

      tx.addr  = vif.AWADDR;
      tx.len   = vif.AWLEN;
      tx.size  = vif.AWSIZE;
      tx.burst = vif.AWBURST;

      tx.data = new[tx.len+1];
      tx.strb = new[tx.len+1];

      `uvm_info(
        "MON_WRITE",
        $sformatf(
          "WRITE START Addr=%0h Len=%0d",
          tx.addr,
          tx.len
        ),
        UVM_LOW
      )

      foreach(tx.data[i])
      begin

        @(posedge vif.ACLK);

        while(!(vif.WVALID && vif.WREADY))
          @(posedge vif.ACLK);

        tx.data[i] = vif.WDATA;
        tx.strb[i] = vif.WSTRB;

        `uvm_info(
          "MON_WRITE",
          $sformatf(
            "Beat=%0d Data=%0h Strb=%0h",
            i,
            tx.data[i],
            tx.strb[i]
          ),
          UVM_LOW
        );

        if(vif.WLAST)
          break;

        @(posedge vif.ACLK);

        while(vif.WVALID && vif.WREADY)
          @(posedge vif.ACLK);

      end

      `uvm_info(
        "MON_WRITE",
        "ALL WRITE BEATS CAPTURED",
        UVM_LOW
      );

      mon_ap.write(tx);

      `uvm_info(
        "MON_WRITE",
        tx.convert2string(),
        UVM_LOW
      );

    end

  endtask

 

 task monitor_read();

  axi_transaction tx;

  @(posedge vif.ACLK);

  if(vif.ARVALID && vif.ARREADY)
  begin

    tx = axi_transaction::type_id::create("rd_tx");

    tx.write = 0;
    tx.read  = 1;

    tx.addr  = vif.ARADDR;
    tx.len   = vif.ARLEN;
    tx.size  = vif.ARSIZE;
    tx.burst = vif.ARBURST;

    tx.rdata = new[tx.len+1];

    `uvm_info(
      "MON_READ",
      $sformatf(
        "READ START Addr=%0h Len=%0d",
        tx.addr,
        tx.len
      ),
      UVM_LOW
    )

    foreach(tx.rdata[i])
    begin

      @(posedge vif.ACLK);

      while(!(vif.RVALID && vif.RREADY))
        @(posedge vif.ACLK);

      tx.rdata[i] = vif.RDATA;

      `uvm_info(
        "MON_READ",
        $sformatf(
          "Beat=%0d Data=%0h",
          i,
          tx.rdata[i]
        ),
        UVM_LOW
      );

      if(vif.RLAST)
        break;

    end

    mon_ap.write(tx);

    `uvm_info(
      "MON_READ",
      tx.convert2string(),
      UVM_LOW
    );

  end

endtask
endclass

// AGENT


class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)
  axi_driver    drv;
  axi_monitor   mon;
  axi_sequencer seqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv  = axi_driver   ::type_id::create("drv",  this);
    mon  = axi_monitor  ::type_id::create("mon",  this);
    seqr = axi_sequencer::type_id::create("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass



// SCOREBOARD — WSTRB masking applied


class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_transaction, axi_scoreboard) sb_port;

  bit [31:0] ref_mem [0:255];

  int pass_count;
  int fail_count;

 
  // CONSTRUCTOR
 

  function new(
    string name,
    uvm_component parent
  );

    super.new(name,parent);

    sb_port = new(
      "sb_port",
      this
    );

    pass_count = 0;
    fail_count = 0;

  endfunction

  

  function void write(
    axi_transaction tx
  );

    int addr;

    

    if(tx.write)
    begin

      addr = tx.addr >> 2;

      foreach(tx.data[i])
      begin

        if(tx.strb[i][0])
          ref_mem[addr][7:0]
          = tx.data[i][7:0];

        if(tx.strb[i][1])
          ref_mem[addr][15:8]
          = tx.data[i][15:8];

        if(tx.strb[i][2])
          ref_mem[addr][23:16]
          = tx.data[i][23:16];

        if(tx.strb[i][3])
          ref_mem[addr][31:24]
          = tx.data[i][31:24];

        addr++;

      end

      `uvm_info(
        "SB",
        "WRITE STORED IN REF MODEL",
        UVM_LOW
      )

    end

  

    if(tx.read)
    begin

      addr = tx.addr >> 2;

      foreach(tx.rdata[i])
      begin

        if(tx.rdata[i] === ref_mem[addr])
        begin

          pass_count++;

          `uvm_info(
            "SB",
            $sformatf(
              "PASS Addr=%0d Exp=%0d Act=%0d",
              addr,
              ref_mem[addr],
              tx.rdata[i]
            ),
            UVM_LOW
          )

        end

        else
        begin

          fail_count++;

          `uvm_error(
            "SB",
            $sformatf(
              "FAIL Addr=%0d Exp=%0d Act=%0d",
              addr,
              ref_mem[addr],
              tx.rdata[i]
            )
          )

        end

        addr++;

      end

    end

  endfunction

  

  function void report_phase(
    uvm_phase phase
  );

    `uvm_info(
      "SB_SUMMARY",
      $sformatf(
        "PASS=%0d FAIL=%0d",
        pass_count,
        fail_count
      ),
      UVM_NONE
    )

  endfunction

endclass


// COVERAGE


class axi_coverage extends uvm_subscriber #(axi_transaction);

  `uvm_component_utils(axi_coverage)

  axi_transaction tx;

  

  covergroup axi_cg;

    option.per_instance = 1;

   

    AWLEN_CP : coverpoint tx.len
    {
      bins short_burst  = {[0:3]};
      bins medium_burst = {[4:7]};
      bins long_burst   = {[8:15]};
    }


    AWBURST_CP : coverpoint tx.burst
    {
      bins FIXED = {2'b00};
      bins INCR  = {2'b01};
      bins WRAP  = {2'b10};
    }

   

    AWSIZE_CP : coverpoint tx.size
    {
      bins BYTE     = {3'b000};
      bins HALFWORD = {3'b001};
      bins WORD     = {3'b010};
      bins DWORD    = {3'b011};
    }

  

    LEN_X_BURST : cross AWLEN_CP, AWBURST_CP;

  endgroup

  

  function new(
    string name,
    uvm_component parent
  );

    super.new(name,parent);

    axi_cg = new();

  endfunction

 

  function void write(
    axi_transaction t
  );

    tx = t;

    axi_cg.sample();

    `uvm_info(
      "COV",
      $sformatf(
        "Coverage Sampled Len=%0d Burst=%0d Size=%0d",
        tx.len,
        tx.burst,
        tx.size
      ),
      UVM_LOW
    )

  endfunction

  

  function void report_phase(
    uvm_phase phase
  );

    `uvm_info(
      "COVERAGE",
      $sformatf(
        "Functional Coverage = %0.2f%%",
        axi_cg.get_coverage()
      ),
      UVM_NONE
    )

  endfunction

endclass

// ENV


class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  axi_agent      agent;
  axi_scoreboard sb;
  axi_coverage   cov;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = axi_agent     ::type_id::create("agent", this);
    sb    = axi_scoreboard::type_id::create("sb",    this);
    cov   = axi_coverage  ::type_id::create("cov",   this);
  endfunction
  function void connect_phase(uvm_phase phase);
    agent.mon.mon_ap.connect(sb.sb_port);
    agent.mon.mon_ap.connect(cov.analysis_export);
  endfunction
endclass


// TEST

class axi_test extends uvm_test;

  `uvm_component_utils(axi_test)

  axi_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi_write_burst_seq wr_seq;
    axi_read_burst_seq  rd_seq;

    phase.raise_objection(this);

    wr_seq = axi_write_burst_seq::type_id::create("wr_seq");
    wr_seq.start(env.agent.seqr);

    
    #50;

    rd_seq = axi_read_burst_seq::type_id::create("rd_seq");
    rd_seq.start(env.agent.seqr);

    #100;
    phase.drop_objection(this);
  endtask

endclass



// TOP

module tb_top;

 
  bit clk;

  initial
  begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz clock
  end

 

  initial
  begin
    $dumpfile("axi_wave.vcd");
    $dumpvars(0, tb_top);
  end

  

  axi_if vif();

  assign vif.ACLK = clk;

  

  initial
  begin
    vif.ARESETN = 0;

    repeat(5)
      @(posedge clk);

    vif.ARESETN = 1;
  end

 

  axi_slave_phase1 dut
  (
    .ACLK    (vif.ACLK),
    .ARESETN (vif.ARESETN),

    
    .AWADDR  (vif.AWADDR),
    .AWLEN   (vif.AWLEN),
    .AWSIZE  (vif.AWSIZE),
    .AWBURST (vif.AWBURST),
    .AWVALID (vif.AWVALID),
    .AWREADY (vif.AWREADY),

   
    .WDATA   (vif.WDATA),
    .WSTRB   (vif.WSTRB),
    .WLAST   (vif.WLAST),
    .WVALID  (vif.WVALID),
    .WREADY  (vif.WREADY),

   
    .BRESP   (vif.BRESP),
    .BVALID  (vif.BVALID),
    .BREADY  (vif.BREADY),

   
    .ARADDR  (vif.ARADDR),
    .ARLEN   (vif.ARLEN),
    .ARSIZE  (vif.ARSIZE),
    .ARBURST (vif.ARBURST),
    .ARVALID (vif.ARVALID),
    .ARREADY (vif.ARREADY),

    
    .RDATA   (vif.RDATA),
    .RRESP   (vif.RRESP),
    .RLAST   (vif.RLAST),
    .RVALID  (vif.RVALID),
    .RREADY  (vif.RREADY)
  );

  

  initial
  begin

    uvm_config_db #(virtual axi_if)::set
    (
      null,
      "*",
      "vif",
      vif
    );

    run_test("axi_test");

  end

endmodule
