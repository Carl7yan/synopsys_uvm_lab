module router_test_top;
  parameter simulation_cycle = 100 ;
  bit  SystemClock;

  router_io sigs(SystemClock);
  host_io   host(SystemClock); // ral?
  router    dut(sigs, host);

  initial begin
    forever #(simulation_cycle/2) SystemClock = ~SystemClock ;
  end
endmodule  
