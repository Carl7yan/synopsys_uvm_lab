`ifndef RESET_SEQUENCE__SV
`define RESET_SEQUENCE__SV


class reset_tr extends uvm_sequence_item;
  typedef enum {ASSERT, DEASSERT} kind_e; // a control command field called kind

// For example, if the reset signal need to be asserted for 2 cycles then de-asserted for 15 cycles, the potential code might:
// reset_tr tr = reset_tr::type_id::create("tr");
// tr.randomize() with {kind == ASSERT; cycles == 2;};
// tr.randomize() with {kind == DEASSERT; cycles == 15};

  rand kind_e kind;
  rand int unsigned cycles = 1;

  `uvm_object_utils_begin(reset_tr)
    `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
    `uvm_field_int(cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "reset_tr");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new
endclass

class reset_sequence extends uvm_sequence#(reset_tr);
  `uvm_object_utils(reset_sequence)

  function new(string name = "reset_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  task body();
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if (starting_phase != null)
      starting_phase.raise_objection(this);
    `uvm_info("RESET", "Executing Reset", UVM_MEDIUM);
    // assert reset for 2 cycles, followed by DEASSERT of reset for 15 cyles.
    `uvm_do_with(req, {kind == ASSERT; cycles == 2;});
    `uvm_do_with(req, {kind == DEASSERT; cycles == 15;});

    if(starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass

`endif
