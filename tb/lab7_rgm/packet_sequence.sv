`ifndef PACKET_SEQUENCE__SV
`define PACKET_SEQUENCE__SV

import packet_seq_lib_pkg::*;
class packet_sequence extends uvm_sequence #(packet);
  int       item_count = 10;
  int       port_id    = -1;
  bit[15:0] da_enable  = '1;
  int       valid_da[$];

  `uvm_object_utils_begin(packet_sequence)
    `uvm_field_int(item_count, UVM_ALL_ON)
    `uvm_field_int(port_id, UVM_ALL_ON)
    `uvm_field_int(da_enable, UVM_ALL_ON)
    `uvm_field_queue_int(valid_da, UVM_ALL_ON)
  `uvm_object_utils_end

  function void pre_randomize();
    uvm_config_db#(int)::get(m_sequencer, "", "item_count", item_count);
    uvm_config_db#(int)::get(m_sequencer, "", "port_id", port_id);
    uvm_config_db#(bit[15:0])::get(m_sequencer, "", "da_enable", da_enable);
    if (!(port_id inside {-1, [0:15]})) begin
      `uvm_fatal("CFGERR", $sformatf("Illegal port_id value of %0d", port_id));
    end

    valid_da.delete();
    for (int i=0; i<16; i++)
      if (da_enable[i])
        valid_da.push_back(i);
  endfunction

  function new(string name = "packet_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual task body();
    uvm_sequence_base parent;

    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    uvm_config_db#(int)::get(m_sequencer, "*", "item_count", item_count);

    parent = get_parent_sequence();
    if (parent != null) begin
      starting_phase = parent.starting_phase;
    end

    if (starting_phase != null) begin
      uvm_objection objection = starting_phase.get_objection();
      objection.set_drain_time(this, 1us);
      starting_phase.raise_objection(this);
    end

    repeat(item_count) begin
      `uvm_do_with(req, {if (port_id == -1) sa inside {[0:15]}; else sa == port_id; da inside valid_da;});
    end

    if (starting_phase != null) begin
      starting_phase.drop_objection(this);
    end
 endtask

endclass

`endif
