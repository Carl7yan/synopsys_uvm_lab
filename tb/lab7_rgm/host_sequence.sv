`ifndef HOST_SEQUENCE__SV
`define HOST_SEQUENCE__SV

`include "host_data.sv"
`include "ral_host_regmodel.sv"



// a sequence to configure the DUT PORT_LOCK register so that all ports are enabled

// The host_bfm_sequence class is designed to clear the DUT PORT_LOCK register
// using the host_driver without using RAL.
class host_bfm_sequence extends uvm_sequence #(host_data);
  `uvm_object_utils(host_bfm_sequence)

  function new(string name = "host_bfm_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction


  // Develop a body() method that reads and writes the DUT configuration fields
  // with the `uvm_do_with macro by manually specifying the address, data and operation.
  virtual task body();
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (starting_phase != null)
      starting_phase.raise_objection(this);

      // read and print the content of PORT_LOCK register at address 16'h0100
    `uvm_do_with(req, {addr == 'h100; kind == host_data::READ;});
    `uvm_info("HOST BFM READ", {"\n", req.sprint()}, UVM_MEDIUM);

      // write all one's to the register to enable all ports
    `uvm_do_with(req, {addr == 'h100; data == '1; kind == host_data::WRITE;});
    `uvm_info("HOST BFM WRITE", {"\n", req.sprint()}, UVM_MEDIUM);

      // read and print the content of the register back to verify it is correctly configured.
    `uvm_do_with(req, {addr == 'h100; kind == host_data::READ;});
    `uvm_info("HOST BFM READ", {"\n", req.sprint()}, UVM_MEDIUM);

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask

endclass

// create sequence using UVM registers
// This is the RAL configuration sequence.
// Because it is a RAL sequence class, it must extend from the uvm_reg_sequence base class.
class host_ral_sequence extends uvm_reg_sequence #(uvm_sequence #(host_data));

  // Create an instance of ral_block_host_regmodel called regmodel.
  ral_block_host_regmodel regmodel;

  
  `uvm_object_utils(host_ral_sequence)

  function new(string name = "host_ral_sequence");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  // Define a body() task that configures the DUT register with
  // the exact same information as host_bfm_sequence above.
  // Except use UVM register representation rather than direct access.
  virtual task body();
    uvm_status_e status;
    uvm_reg_data_t data;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (starting_phase != null)
      starting_phase.raise_objection(this);
    regmodel.PORT_LOCK.read(.status(status), .value(data), .path(UVM_FRONTDOOR), .parent(this));
    `uvm_info("RAL READ", $sformatf("PORT_LOCK= %2h", data), UVM_MEDIUM);
    regmodel.PORT_LOCK.write(.status(status), .value('1), .path(UVM_FRONTDOOR), .parent(this));
    `uvm_info("RAL WRITE", $sformatf("PORT_LOCK= %2h", '1), UVM_MEDIUM);
    regmodel.PORT_LOCK.read(.status(status), .value(data), .path(UVM_FRONTDOOR), .parent(this));
    `uvm_info("RAL READ", $sformatf("PORT_LOCK= %2h", data), UVM_MEDIUM);
    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask

endclass

`endif
