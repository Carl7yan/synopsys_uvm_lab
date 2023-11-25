`ifndef TEST_COLLECTION_SV
`define TEST_COLLECTION_SV

`include "router_env.sv"

class test_base extends uvm_test;
  `uvm_component_utils(test_base)
  router_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    // "%m": current hierarchical path
    // debug to see things execute sequentially
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    env = router_env::type_id::create("env", this);

    uvm_config_db#(virtual router_io)::set(this, "env.i_agent[*]", "router_io", router_test_top.sigs);
    uvm_config_db#(virtual router_io)::set(this, "env.o_agent[*]", "router_io", router_test_top.sigs);

    uvm_config_db#(virtual router_io)::set(this, "env.r_agent", "router_io", router_test_top.sigs);

    // Update Test to use sequence in library There are three ways to register sequences into a sequence library:
    // 1 - Use `uvm_add_to_seq_lib() macro. It will add the sequence to the sequence library for all tests
    // 2 - Use the sequence library class's add_typewide_sequence() method. It will add the sequence to the sequence library only for the test thst called the method.
    // 3 - Use the sequence library object's add_sequence() method. It requires that an instance of the sequence library be constructed, then the add_sequence() method called via this sequence library handle will only affect the seqr that's configured to use this particular sequence library object.
    packet_seq_lib::add_typewide_sequence(packet_sequence::get_type()); //register sequences into a sequence library
  endfunction: build_phase


  virtual function void final_phase(uvm_phase phase);
  // or "start_of_simulation_phase"
    super.final_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    uvm_top.print_topology();
    // default: (uvm_default_table_priter);
    // try: (uvm_default_tree_printer);
    factory.print(); // see registered class types
    // "factory override" to modify the test
  endfunction

endclass: test_base



`include "packet_da_3.sv"
class test_da_3_inst extends test_base;
  `uvm_component_utils(test_da_3_inst)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  // inst_override to configure the seqr to use packet_da_3 instead of packet
  // "factory override" to modifying the test
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    set_inst_override_by_type("env.i_agent*.seqr.*", packet::get_type(), packet_da_3::get_type());
  endfunction
endclass

  // create a new test using type_override to override all instances of packet with packet_da_3 globally
class test_da_3_type extends test_base;
  `uvm_component_utils(test_da_3_type)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    set_type_override_by_type(packet::get_type(), packet_da_3::get_type());
  endfunction
endclass: test_da_3_type

// a new test to set the packet_sequence's configuration fields
class test_da_3_seq extends test_base;
  `uvm_component_utils(test_da_3_seq)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // (in UVM, all configuration must be done via the sequencer through component path)
    uvm_config_db#(bit[15:0])::set(this, "env.i_agent*.seqr", "da_enable", 16'h0008); // set the packet_sequence's da_enable to 16'h0008, to enable destination address to 3
    uvm_config_db#(int)::set(this, "env.i_agent*.seqr", "item_count", 1);   // set the packet_sequence's item_count to 20
  endfunction
endclass


// the sequence library executes 10 of its registered child sequences by default, the number and execution type can be changed  using uvm_sequence_library_cfg class
// with the sequence library, you can quickly build up a collection of tests, to focus on what need to be verified
class test_seq_lib_cfg extends test_base;
  uvm_sequence_library_cfg seq_cfg; // create an instance of uvm_sequence_library_cfg, call it seq_cfg.
  `uvm_component_utils(test_seq_lib_cfg)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // seq_cfg object is constructed with UVM_SEQ_LIB_RAND mode and the max_random_count and min_random_count to 1
    seq_cfg = new("seq_cfg", UVM_SEQ_LIB_RAND, 10, 5);
    // configure all agent seqr's sequence library to use this configuration
    uvm_config_db#(uvm_sequence_library_cfg)::set(this, "env.i_agent*.seqr.main_phase", "default_sequence.config", seq_cfg);
  endfunction
endclass
`endif
