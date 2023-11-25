`ifndef ROUTER_ENV__SV
`define ROUTER_ENV__SV

`include "input_agent.sv"
`include "reset_agent.sv"
`include "output_agent.sv"
`include "ms_scoreboard.sv"

// add host components to env
`include "host_agent.sv"


class router_env extends uvm_env;
  input_agent  i_agent[16];
  scoreboard   sb;
  output_agent o_agent[16];
  reset_agent  r_agent;

  host_agent h_agent;

  // Create an instance of ral_block_host_regmodel call it regmodel.
  ral_block_host_regmodel regmodel;


  `uvm_component_utils(router_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    foreach (i_agent[i]) begin
      i_agent[i] = input_agent::type_id::create($sformatf("i_agent[%0d]", i), this);
      uvm_config_db #(int)::set(this, i_agent[i].get_name(), "port_id", i);
      uvm_config_db #(uvm_object_wrapper)::set(this, {i_agent[i].get_name(), ".", "seqr.main_phase"}, "default_sequence", packet_sequence::get_type());
    end

    sb = scoreboard::type_id::create("sb", this);
    foreach (o_agent[i]) begin
      o_agent[i] = output_agent::type_id::create($sformatf("o_agent[%0d]",i),this);
      uvm_config_db #(int)::set(this, o_agent[i].get_name(), "port_id", i);
    end

    r_agent = reset_agent::type_id::create("r_agent", this);
    uvm_config_db #(uvm_object_wrapper)::set(this, {r_agent.get_name(), ".", "seqr.reset_phase"}, "default_sequence", reset_sequence::get_type());

    h_agent = host_agent::type_id::create("h_agent", this);
    // Configure the host agent's sequencer to execute host_bfm_sequence at the configure_phase.
    uvm_config_db #(uvm_object_wrapper)::set(this, {h_agent.get_name(), ".", "seqr.configure_phase"}, "default_sequence", host_bfm_sequence::get_type());


    // If you want the regmodel to be configurable at the test or parent environment level,
    // uncomment the following.  (Not needed for this lab)
    uvm_config_db #(ral_block_host_regmodel)::get(this, "", "regmodel", regmodel);


    if (regmodel == null) begin // Check to see if regmodel is null.
      string hdl_path; // 1. Add a string field call it hdl_path.

      // 2. Retrieve the hdl_path string with uvm_config_db.
      if (!uvm_config_db #(string)::get(this, "", "hdl_path", hdl_path)) begin
        `uvm_warning("HOSTCFG", "HDL path for backdoor not set!"); // if hdl_path is not configured, issue a warning
      end
      regmodel = ral_block_host_regmodel::type_id::create("regmodel", this); 
      regmodel.build(); // build the RAL representation by the regmodel's build()
      regmodel.lock_model(); // lock the RAL structure/representation and create the address map by the regmodel's lock_model()
      regmodel.set_hdl_path_root(hdl_path); // set hdl root path by regmodel's set_hdl_path_root()
    end

  endfunction

  virtual function void connect_phase(uvm_phase phase);

    // Create and construct an instance of reg_adapter call it adapter.
    reg_adapter adapter = reg_adapter::type_id::create("adapter", this);

    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // Tie the regmodel to a sequencer by calling the set_sequencer() method in regmodel's default_map member.
    regmodel.default_map.set_sequencer(h_agent.seqr, adapter);


    foreach (i_agent[i]) begin
      i_agent[i].analysis_port.connect(sb.before_export);
    end
    foreach (o_agent[i]) begin
      o_agent[i].analysis_port.connect(sb.after_export);
    end
  endfunction
endclass

`endif
