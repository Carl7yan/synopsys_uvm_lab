`ifndef SCOREBOARD__SV
`define SCOREBOARD__SV

class scoreboard extends uvm_scoreboard;
 
  // Lab 5 - Task 6, Step 2
  //
  // Add an instance of uvm_in_order_class_comparator typed to packet.  Call it comparator.
  //
  // ToDo
  uvm_in_order_class_comparator #(packet) comparator;


  // Lab 5 - Task 6, Step 3
  //
  // Create two uvm_analysis_export, one called before_export and the other after_export.
  //
  // ToDo
  uvm_analysis_export #(packet) before_export;
  uvm_analysis_export #(packet) after_export;


  `uvm_component_utils(scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // Lab 5 - Task 6, Step 4
    //
    // Construct the comparator.
    // Set the two analysis exports to the corresponding exports in the comparators.
    //
    // ToDo
    comparator = uvm_in_order_class_comparator #(packet)::type_id::create("comparator", this);
    before_export = comparator.before_export;
    after_export  = comparator.after_export;


  endfunction

  //
  // You should always print the comparison results in the report phase/
  // This is done for you.
  //
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    `uvm_info("Scoreboard Report",
      $sformatf("Comparator Matches = %0d, Mismatches = %0d", comparator.m_matches, comparator.m_mismatches), UVM_MEDIUM);
  endfunction

endclass

`endif

