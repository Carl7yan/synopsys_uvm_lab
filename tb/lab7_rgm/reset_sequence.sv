`ifndef RESET_SEQUENCE__SV
`define RESET_SEQUENCE__SV

class reset_tr extends uvm_sequence_item;
  typedef enum {ASSERT, DEASSERT} kind_e;
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

class reset_sequence extends uvm_sequence #(reset_tr);
  `uvm_object_utils(reset_sequence)

  function new(string name = "reset_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  task body();
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    `uvm_do_with(req, {kind == ASSERT; cycles == 2;});
    `uvm_do_with(req, {kind == DEASSERT; cycles == 15;});


    if (starting_phase != null)
      starting_phase.drop_objection(this);
   endtask

endclass

`endif
