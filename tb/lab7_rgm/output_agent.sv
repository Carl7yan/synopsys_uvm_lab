`ifndef OUTPUT_AGENT__SV
`define OUTPUT_AGENT__SV

`include "oMonitor.sv"

class output_agent extends uvm_agent;
  virtual router_io sigs;
  int               port_id = -1;
  oMonitor          mon;
  uvm_analysis_port #(packet) analysis_port;

  `uvm_component_utils_begin(output_agent)
    `uvm_field_int(port_id, UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    uvm_config_db#(int)::get(this, "", "port_id", port_id);
    uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs);

    mon  = oMonitor::type_id::create("mon", this);
    uvm_config_db#(int)::set(this, "mon", "port_id", port_id);
    uvm_config_db#(virtual router_io)::set(this, "mon", "router_io", sigs);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    this.analysis_port = mon.analysis_port;
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    `uvm_info("AGNTCFG", $sformatf("Using port_id of %0d", port_id), UVM_MEDIUM);
  endfunction: start_of_simulation_phase

endclass

`endif
