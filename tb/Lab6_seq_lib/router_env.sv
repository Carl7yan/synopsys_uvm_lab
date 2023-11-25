`ifndef ROUTER_ENV__SV
`define ROUTER_ENV__SV

`include "input_agent.sv"
`include "reset_agent.sv"

`include "output_agent.sv"
`include "ms_scoreboard.sv"

class router_env extends uvm_env;

  input_agent i_agent[16]; // an array of agent to enable all ports

  scoreboard sb;
  output_agent o_agent[16];

  reset_agent r_agent;

  `uvm_component_utils(router_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    foreach (i_agent[i]) begin
      i_agent[i] = input_agent::type_id::create($sformatf("i_agent[%0d]", i), this);
      uvm_config_db #(int)::set(this, i_agent[i].get_name(), "port_id", i);

      // update env to set the seqr to execute sequence library
      // use the sequence library (packet_seq_lib) instead of packet sequence (packet_sequence)
      // uvm_config_db #(uvm_object_wrapper)::set(this, {i_agent[i].get_name(), ".", "seqr.main_phase"}, "default_sequence", packet_sequence::get_type());
      uvm_config_db #(uvm_object_wrapper)::set(this, {i_agent[i].get_name(), ".", "seqr.main_phase"}, "default_sequence", packet_seq_lib::get_type());
      // set i_agent's seqr to execute packet_sequence as the default_sequence in main_phase
    end

    sb = scoreboard::type_id::create("sb", this);
    foreach (o_agent[i]) begin
      o_agent[i] = output_agent::type_id::create($sformatf("o_agent[%0d]",i),this);
      uvm_config_db #(int)::set(this, o_agent[i].get_name(), "port_id", i);
    end

    r_agent = reset_agent::type_id::create("r_agent", this);
    uvm_config_db #(uvm_object_wrapper)::set(this, "r_agent.seqr.reset_phase", "default_sequence", reset_sequence::get_type());
    // set r_agent's seqr to execute reset_sequence as the default_sequence in reset_phase
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    foreach (i_agent[i]) begin
      i_agent[i].analysis_port.connect(sb.before_export);
    end
    foreach (o_agent[i]) begin
      o_agent[i].analysis_port.connect(sb.after_export);
    end
  endfunction

endclass: router_env
`endif
