package packet_seq_lib_pkg;
  import uvm_pkg::*;
  
  // The packet class is moved inside the package.
  class packet extends uvm_sequence_item;
    rand bit [3:0] sa, da;
    rand bit [7:0] payload[$];

  `uvm_object_utils_begin(packet)
    `uvm_field_int(sa, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(da, UVM_ALL_ON)
    `uvm_field_queue_int(payload, UVM_ALL_ON)
  `uvm_object_utils_end

    constraint valid {
      payload.size inside {[1:10]};
    }
  
    function new(string name="packet");
      super.new(name);
      `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction
  endclass

  // create a sequence library that can be reused through integration of blocks and across different projects to raise the productivity of the verification environment
  // sequence library is a collection of sequences packaged
  // the base sequence library
  class packet_seq_lib extends uvm_sequence_library #(packet);
    // Every sequence library have the identical structure, typed to a particular sequence item
    // The only thing that changes is the name of the class and the sequence item type.
    // Notice that there are no sequence registered in the library, the sequence needed by the tests will be registered into the library on a test by test basis. If there are common sequences that's required by all tests when using the library, then these sequences can be included in the package and registered into the library. 
    `uvm_object_utils(packet_seq_lib)
    `uvm_sequence_library_utils(packet_seq_lib)

    function new(string name = "packet_seq_lib");
      super.new(name);
      `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
      init_sequence_library(); // this call are required to to be able to populate the sequence library with sequences are registered with it or any of its base classes.

    endfunction
  endclass
endpackage
