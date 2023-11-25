`ifndef INPUT_AGENT__SV
`define INPUT_AGENT__SV

`include "packet_sequence.sv"
`include "driver.sv"
`include "iMonitor.sv"
typedef uvm_sequencer #(packet) packet_sequencer;


class input_agent extends uvm_agent;
  virtual router_io sigs;
  int port_id = -1;

  packet_sequencer seqr;
  driver drv;
  iMonitor mon;
  uvm_analysis_port #(packet) analysis_port;

  `uvm_component_utils_begin(input_agent)
    `uvm_field_int(port_id, UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    uvm_config_db#(int)::get(this, "", "port_id", port_id);
    uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs);

    if (is_active == UVM_ACTIVE) begin
      seqr = packet_sequencer::type_id::create("seqr", this);
      drv  = driver::type_id::create("drv", this);

      uvm_config_db#(int)::set(this, "drv", "port_id", port_id);
      uvm_config_db#(int)::set(this, "seqr", "port_id", port_id);
      uvm_config_db#(virtual router_io)::set(this, "drv", "router_io", sigs);
      uvm_config_db#(virtual router_io)::set(this, "seqr", "router_io", sigs);
    end

    mon = iMonitor::type_id::create("mon", this);
    uvm_config_db#(int)::set(this, "mon", "port_id", port_id);
    uvm_config_db#(virtual router_io)::set(this, "mon", "router_io", sigs);
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
    this.analysis_port = mon.analysis_port;
  endfunction: connect_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    `uvm_info("AGNTCFG", $sformatf("Using port_id of %0d", port_id), UVM_MEDIUM);
  endfunction

endclass: input_agent
`endif
