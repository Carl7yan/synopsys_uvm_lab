program automatic test;
import uvm_pkg::*;

`include "test_collection.sv"

initial begin
  uvm_reg::include_coverage("*", UVM_CVR_ALL);
  $timeformat(-9, 1, "ns", 10);
  run_test();
end

endprogram

