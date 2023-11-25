`ifndef HOST_DATA__SV
`define HOST_DATA__SV

// implement all components supporting the configration without RAL
// contains data and address field with two possible kinds of operation: read and write
//
class host_data extends uvm_sequence_item;
  typedef enum {READ, WRITE} kind_e;
  rand kind_e    kind;
  rand bit[15:0] addr;
  rand bit[15:0] data;
 
  `uvm_object_utils_begin(host_data)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="host_data");
    super.new(name);
    `uvm_info("Trace", $sformatf("%m"), UVM_HIGH);
  endfunction
endclass


// --------------------------------------------------------------------------------------
// Implement UVM Register Translator
//
// implement a <UVM register to host bus> and <ost bus to UVM Register> translator
// for the UVM Register to be processed by the host driver
//
// For the sake of minimizing the number of files in each lab directory, you will be
// creating the translator class in the same file as the host_data class.
// --------------------------------------------------------------------------------------

class reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_adapter)

  function new(string name="reg_adapter");
    super.new(name);
    `uvm_info("Trace", $sformatf("%m"), UVM_HIGH);
  endfunction

  // ------------------------------------------------------------------------------------
  // copy the generic UVM register object (rw argument of method) content into
  // a host_data object and return the host_data handle in reg2bus()
  // ------------------------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    host_data tr;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // Construct the host_data object (tr).
    // Then, convert the UVM register data to the host_data type and return the result.
    tr = host_data::type_id::create("tr");
    tr.kind = (rw.kind == UVM_READ) ? host_data::READ : host_data::WRITE;
    tr.addr = rw.addr;
    tr.data = rw.data;
    return tr;

  endfunction


  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    host_data tr;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    // Check to see if bus_item in the first argument is host_data type.  If not, print a fatal message.
    // Otherwise, populate the methods to converting the bus_item content back to UVM register data type.
    // then, copy the host_data object content into the UVM register object (rw)
    if (!$cast(tr, bus_item)) begin
      `uvm_fatal("NOT_HOST_REG_TYPE", "bus_item is not correct type");
    end
    rw.kind = (tr.kind == host_data::READ) ? UVM_READ : UVM_WRITE;
    rw.addr = tr.addr;
    rw.data = tr.data;
    rw.status = UVM_IS_OK;

  endfunction
endclass
`endif
