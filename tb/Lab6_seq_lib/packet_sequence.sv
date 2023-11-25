`ifndef PACKET_SEQUENCE__SV
`define PACKET_SEQUENCE__SV

import packet_seq_lib_pkg::*;
// Because the packet class now resides inside the packet sequence library package. This include is not needed
//`include "packet.sv"

class packet_sequence extends uvm_sequence #(packet); // sequence are where stimulus are created
  // configuration field to make packet_sequence configurable

  int item_count = 10; // how many packet to the driver per execution of body() task

  int port_id = -1; // constrain source address (input port) in input_agent
  // the DUT has 16 input ports to be tested, each port has one input agent with a port_id (specifying which port to exercise) to drive stimulus

  // If port_id is inside the range of {[0:15]}, then the source address shall be port_id.
  // If port_id is -1 (unconfigured), the source address shall be in the range of {[0:15]}
  // port_id outside the range of {-1, {[0:15]} is not allowed.

  bit [15:0] da_enable = '1; // to ENABLE corresponding destination address to be generated. A value of 1 in a particular bit position will enable the corresponding address as a valid address to generate.
  // the default value is '1, meaning that all addresses are enabled
  // A value of 0 prohibit the corresponding address from being generated.

  // if the sequence were to be configured to generate only packets for destination address 3, then the da_enable need to be configured as:
  // 16'b0000_0000_0000_1000

  int valid_da[$]; // This queue is populated based on the value of da_enable. To simplify coding to constrain da
  // if da_enable is 16'b0000_0011_0000_1000, then the valid_da queue
  // will populated with 3, 8 and 9.
 
  `uvm_object_utils_begin(packet_sequence)
    `uvm_field_int(item_count, UVM_ALL_ON)
    `uvm_field_int(port_id, UVM_ALL_ON)
    `uvm_field_int(da_enable, UVM_ALL_ON)
    `uvm_field_queue_int(valid_da, UVM_ALL_ON)
  `uvm_object_utils_end

  // Since the first thing that the sequencer performs is the randomization of its default_sequence
  // so it's good to have a pre_randomiza() method to retrieve the configuration fields and populate the valid_da queue
  function void pre_randomize();
    // Retreive the configuration fields
    uvm_config_db#(int)::get(m_sequencer, "", "item_count", item_count);
    uvm_config_db#(int)::get(m_sequencer, "", "port_id", port_id);
    uvm_config_db#(bit[15:0])::get(m_sequencer, "", "da_enable", da_enable);
    if(!(port_id inside {-1, [0:15]})) begin
      `uvm_fatal("CFGERR", $sformatf("Illegal port_id value of %0d", port_id));
    end

    valid_da.delete();
    for (int i = 0; i < 16; i++)
      if (da_enable[i])
        valid_da.push_back(i);
        // The valid_da queue must be populated with legal set of addresses as specified by the da_enable field. 
  endfunction

  function new(string name = "packet_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual task body();
    // when execute sequences by configuring the seqr to execute the sequence of choice via the default_sequence configuration field, the seqr treated the sequence as the top sequence, the top sequence will be provided witn the executing phase (starting_phase) information by seqr
    // when a sequence is inside a sequence library, that sequence is no longer the top sequence, it's a child sequence of the sequence library. So, the sequence no longer has access to starting_phase by default, I need to fetch the starting_phase from the parent sequence.
    // create a parent sequence handle called parent
    uvm_sequence_base parent;

    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    uvm_config_db#(int)::get(m_sequencer, "*", "item_count", item_count);

    // prepare the existing packet sequence for possible registration into sequence library
    parent = get_parent_sequence(); // to retrieve the parent sequence handle
    if(parent != null) begin
      starting_phase = parent.starting_phase; // set the sequence's starting_phase to parent sequence's starting_phase. This is necessary, because child sequences do not have starting_phase of their own.
      // if this is not added, the starting_phase will be null when executing this sequence from the sequence library, then phase objection will not be available for setting the drain time, then the final outputs of the DUT may not be observed
    end

    if(starting_phase != null) begin

      // common missing output UVM problem: the number of packets detected in the input is one more than it observed at the output
      // this is due to the latency of the transaction flowing through DUT, since the objection were only raised and dropped on the input side, as soon as the input is done, the UVM simulation thinks everything is done because there are no existing objections.
      // way one: add objection mechanisms to the monitors, but it's costly in terms of performance
      // way two: take care of the expected latency on the input side by implementing an objection drain time.
      // If an an objection drain time is set, then when the objection count reaches 0, the phase must wait for the drain time to elapse before terminating the phase. If another objection is raised during the drain time, the phase objection mechanism starts over and waits for objection count to reach 0 again
      uvm_objection objection = starting_phase.get_objection(); // retrieve the objection handle
      objection.set_drain_time(this, 1us); // set the drain time to 1us

      starting_phase.raise_objection(this);
    end

      //repeat(10) begin //10 ramdom packets
      repeat(item_count) begin

        // `uvm_do(req); 
        // This will give the test the ability to test whether or not the driver drops the packet it is not configured to drive.
        `uvm_do_with(req, {if (port_id == -1) sa inside {[0:15]}; else sa == port_id; da inside valid_da;});
        // if port_id == -1 (unconfigured), the legal values for the source address shall be {[0,15]}.
        // if port_id is configured, then the source address shall be port_id

        // For destination address, the legal values should be picked out of the valid_da array.
      end

    if(starting_phase != null)
      starting_phase.drop_objection(this);
  endtask: body
endclass: packet_sequence
`endif
