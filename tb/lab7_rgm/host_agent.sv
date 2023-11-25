`ifndef HOST_AGENT__SV
`define HOST_AGENT__SV

`include "host_sequence.sv"

typedef uvm_sequencer #(host_data) host_sequencer;
typedef class host_driver;
typedef class host_monitor;

// this host_agent is aside from the DUT specific device drivers
class host_agent extends uvm_agent;
  virtual host_io sigs;     // DUT host interface
  uvm_analysis_port #(host_data) analysis_port;
  host_sequencer seqr;
  host_driver    drv;
  host_monitor   mon;

  `uvm_component_utils(host_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // The agent retrieves virtual interface.
    uvm_config_db#(virtual host_io)::get(this, "", "host_io", sigs);

    if (is_active) begin
      seqr = host_sequencer::type_id::create("seqr", this);
      drv  = host_driver::type_id::create("drv", this);
      uvm_config_db#(virtual host_io)::set(this, "drv", "host_io", sigs);
      uvm_config_db#(virtual host_io)::set(this, "seqr", "host_io", sigs);
    end
    mon = host_monitor::type_id::create("mon", this);
    uvm_config_db#(virtual host_io)::set(this, "mon", "host_io", sigs);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (is_active) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass

class host_driver extends uvm_driver #(host_data);
  virtual host_io sigs;
  event go;

  `uvm_component_utils(host_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (!uvm_config_db#(virtual host_io)::get(this, "", "host_io", sigs)) begin
      `uvm_fatal("CFGERR", "DUT host interface not set");
    end
  endfunction

  virtual task pre_reset_phase(uvm_phase phase);
    sigs.wr_n    = 'x;
    sigs.address = 'x;
    sigs.data    = 'x;
  endtask

  virtual task reset_phase(uvm_phase phase);
    sigs.wr_n    = '1;
    sigs.address = '1;
    sigs.data    = '1;
  endtask

  virtual task post_reset_phase(uvm_phase phase);
//    -> go;
  endtask

  virtual task run_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
//    suspend();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("RUN", { "Before process\n", req.sprint() }, UVM_FULL);
      data_rw(req);
      `uvm_info("RUN", { "After process\n", req.sprint() }, UVM_FULL);
      seq_item_port.item_done();
    end
  endtask

  virtual task data_rw(host_data req);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    case(req.kind)
      host_data::READ: begin
                        sigs.wr_n = '1;
                        sigs.cb.address <= req.addr;
                        @(sigs.cb);
                        req.data = sigs.cb.data;
                    end
      host_data::WRITE: begin
                         sigs.wr_n = '0;
                         sigs.data = req.data;
                         sigs.cb.address <= req.addr;
                         @(sigs.cb);
                         sigs.wr_n = '1;
                         sigs.data = 'z;
                       end
      default: begin `uvm_fatal("REGERR", "Not a valid Register Command"); end
    endcase
  endtask

  task suspend();
    wait(go.triggered);
  endtask
endclass

class host_monitor extends uvm_monitor;
  uvm_analysis_port #(host_data) analysis_port;
  virtual host_io sigs;
  event go;

  `uvm_component_utils(host_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (!uvm_config_db#(virtual host_io)::get(this, "", "host_io", sigs)) begin
      `uvm_fatal("CFGERR", "DUT host interface not set");
    end
    analysis_port = new("analysis_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    host_data tr;
    suspend();
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    forever begin
      tr = host_data::type_id::create("tr", this);
      data_rw(tr);
      analysis_port.write(tr);
    end
  endtask

  virtual task post_reset_phase(uvm_phase phase);
    -> go;
  endtask

  virtual task data_rw(host_data tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if(!sigs.mon.wr_n) begin
      tr.kind = host_data::WRITE;
      tr.addr = sigs.mon.address;
      tr.data = sigs.mon.data;
      `uvm_info("Got WRITE", {"\n", tr.sprint()}, UVM_DEBUG);
      @(sigs.mon);
    end else begin
      fork
        begin
          fork
            @(sigs.mon.wr_n);
            @(sigs.mon.address);
          join_any
          disable fork;
          tr.addr = sigs.mon.address;
          tr.data = sigs.mon.data;
          if(!sigs.mon.wr_n) begin
            tr.kind = host_data::WRITE;
            `uvm_info("Got WRITE", {"\n", tr.sprint()}, UVM_DEBUG);
          end else begin
            tr.kind = host_data::READ;
            `uvm_info("Got READ", {"\n", tr.sprint()}, UVM_DEBUG);
          end
          @(sigs.mon);
        end
      join
    end
  endtask

  task suspend();
    wait(go.triggered);
  endtask
endclass

`endif
