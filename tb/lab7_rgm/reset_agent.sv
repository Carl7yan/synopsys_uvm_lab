`ifndef RESET_AGENT__SV
`define RESET_AGENT__SV

`include "reset_sequence.sv"

typedef class reset_driver;
typedef class reset_monitor;
typedef uvm_sequencer#(reset_tr) reset_sequencer;

class reset_agent extends uvm_agent;
  virtual router_io sigs;
  reset_sequencer seqr;
  reset_driver  drv;
  reset_monitor mon;

  `uvm_component_utils(reset_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active);
    `uvm_info("RSTCFG", $sformatf("Reset agent %s setting for is_active is: %p", this.get_name(), is_active), UVM_MEDIUM);

    uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs);

    if (is_active == UVM_ACTIVE) begin
      seqr = reset_sequencer::type_id::create("seqr", this);
      drv  = reset_driver::type_id::create("drv", this);
      uvm_config_db#(virtual router_io)::set(this, "drv", "router_io", sigs);
      uvm_config_db#(virtual router_io)::set(this, "seqr", "router_io", sigs);
    end
    mon = reset_monitor::type_id::create("mon", this);
    uvm_config_db#(virtual router_io)::set(this, "mon", "router_io", sigs);
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction: connect_phase
endclass

/*
class reset_tr extends uvm_sequence_item;
  typedef enum {ASSERT, DEASSERT} kind_e;
  rand kind_e kind;
  rand int unsigned cycles = 1;
endclass
*/

class reset_driver extends uvm_driver #(reset_tr);
  virtual router_io sigs;
  `uvm_component_utils(reset_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if (!uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs)) begin
      `uvm_fatal("CFGERR", "Interface for reset driver not set");
    end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask: run_phase

  virtual task drive(reset_tr tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (tr.kind == reset_tr::ASSERT) begin
      sigs.reset_n = 1'b0;
      repeat(tr.cycles) @(sigs.drvClk);
    end else begin
      sigs.reset_n <= '1;
      repeat(tr.cycles) @(sigs.drvClk);
    end
  endtask: drive
endclass

class reset_monitor extends uvm_monitor;
  virtual router_io sigs;
  uvm_analysis_port #(reset_tr) analysis_port;
  `uvm_component_utils(reset_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if (!uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs)) begin
      `uvm_fatal("CFGERR", "Interface for reset monitor not set");
    end

    analysis_port = new("analysis_port", this);
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    forever begin
      reset_tr tr = reset_tr::type_id::create("tr", this);
      detect(tr);
      analysis_port.write(tr);
    end
  endtask: run_phase

  virtual task detect(reset_tr tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    @(sigs.reset_n);
    assert(!$isunknown(sigs.reset_n));
    if (sigs.reset_n == 1'b0) begin
      tr.kind = reset_tr::ASSERT;
    end else begin
      tr.kind = reset_tr::DEASSERT;
    end
  endtask: detect
endclass

`endif
