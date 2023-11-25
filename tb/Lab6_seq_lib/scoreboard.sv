`ifndef SCOREBOARD__SV
`define SCOREBOARD__SV

// scoreboard to make verification environment self-checking 

// due to the basic nature of the UVM comparator and scoreboard, this scoreboard will have unintended mismatches
// one way to isolate the problem is to just test one port
// second way: check ms_scoreboard.sv
class scoreboard extends uvm_scoreboard;
  uvm_in_order_class_comparator #(packet) comparator; 
  // add an instance of in_order comparator typed to check packet objects

  uvm_analysis_export #(packet) before_export; // passing iMonitor packet to comparator
  uvm_analysis_export #(packet) after_export; // passing oMonitor packet to comparator

  `uvm_component_utils(scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    comparator = uvm_in_order_class_comparator #(packet)::type_id::create("comparator", this);

    // set the two analysis exports to the corresponding comparator's exports
    before_export = comparator.before_export;
    after_export = comparator.after_export;
  endfunction

  // print the comparason results in the report phase
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    `uvm_info("Scoreboard Report",
      $sformatf("Comparator Matches = %0d, Mismatches = %0d", comparator.m_matches, comparator.m_mismatches), UVM_MEDIUM);
  endfunction

endclass

`endif
