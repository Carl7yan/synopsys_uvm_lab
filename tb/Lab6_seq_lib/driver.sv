`ifndef DRIVER__SV
`define DRIVER__SV

class driver extends uvm_driver #(packet);

  bit [3:0] sa, da;
  covergroup router_cov;
    coverpoint sa;
    coverpoint da;
    cross sa, da;
  endgroup: router_cov

  virtual router_io sigs;
  int port_id = -1;  // Driver's designated port

  // If port_id matches the packet's source address (sa), driver works. If not, the packet is dropped.

  // If port_id is set in the range of 0 through 15, the driver will only drive the packet it gets from the sequencer through the DUT
  // If port_id is -1 (the default), the driver will drive all packets it gets from the sequencer through the DUT without checking the packet's source address.

  // If port_id is -1 and req.sa is 7, then drive the packet through port7:sigs.drvClk.din[req.sa];
  // If port_id is 3 and req.sa is also 3, then drive the packet through port3: sigs.drvClk.din[req.sa];
  // If port_id is 3 and req.sa is 7, the driver will dropthe packet.
    // (req is the packet handle that sequencer passed to the driver)
  `uvm_component_utils_begin(driver)
    `uvm_field_int(port_id, UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    router_cov = new();
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    uvm_config_db#(int)::get(this, "", "port_id", port_id);
    if (!(port_id inside {-1, [0:15]})) begin
      `uvm_fatal("CFGERR", $sformatf("port_id must be {-1, [0:15]}, not %0d!", port_id));
    end

    uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs);
    if (sigs == null) begin
      `uvm_fatal("CFGERR", "Interface for Driver not set");
    end
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    `uvm_info("DRV_CFG", $sformatf("port_id is: %0d", port_id), UVM_MEDIUM);
  endfunction: start_of_simulation_phase

  virtual task run_phase(uvm_phase phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    forever begin
      seq_item_port.get_next_item(req);

      if (port_id inside {-1, req.sa}) begin // check port_id to see if the driver should accept or drop the packet
        // if port_id == -1, or matches req object's sa field, otherwise drop it without processing

        this.sa = req.sa;
        this.da = req.da;
        // update the covergroup bins with sample()
        this.router_cov.sample();

        send(req);
        // req.print();
        `uvm_info("DRV_RUN", {"\n", req.sprint()}, UVM_MEDIUM); // visualize the number of packets processed by the driver in the UVM Report mechanism
      end

      seq_item_port.item_done();
    end
  endtask: run_phase


  virtual task pre_reset_phase(uvm_phase phase);
    super.pre_reset_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    phase.raise_objection(this);
    if(port_id == -1) begin
      sigs.drvClk.frame_n <= 'x;
      sigs.drvClk.valid_n <= 'x;
      sigs.drvClk.din <= 'x;
    end else begin
      sigs.drvClk.frame_n[port_id] <= 'x;
      sigs.drvClk.valid_n[port_id] <= 'x;
      sigs.drvClk.din[port_id] <= 'x;
    end
    phase.drop_objection(this);
  endtask: pre_reset_phase

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    phase.raise_objection(this);
    if (port_id == -1) begin //not using port_id
      sigs.drvClk.frame_n <= '1;
      sigs.drvClk.valid_n <= '1;
      sigs.drvClk.din <= '0;
    end else begin
      sigs.drvClk.frame_n[port_id] <= '1;
      sigs.drvClk.valid_n[port_id] <= '1;
      sigs.drvClk.din[port_id] <= '0;
    end
    phase.drop_objection(this);
  endtask: reset_phase

  virtual task send(packet tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    send_address(tr);
    send_pad(tr);
    send_payload(tr);
  endtask

  virtual task send_address(packet tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    sigs.drvClk.frame_n[tr.sa] <= 1'b0;
    for(int i = 0; i < 4; i++) begin
      sigs.drvClk.din[tr.sa] <= tr.da[i];
      @(sigs.drvClk);
    end
  endtask

  virtual task send_pad(packet tr);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    sigs.drvClk.din[tr.sa] <= 1'b1;
    sigs.drvClk.valid_n[tr.sa] <= 1'b1;
    repeat(5) @(sigs.drvClk);
  endtask

  virtual task send_payload(packet tr);
    logic [7:0] datum;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    while(!sigs.drvClk.busy_n[tr.sa]) @(sigs.drvClk);
    foreach(tr.payload[index]) begin
      datum = tr.payload[index];
      for(int i = 0; i < $size(tr.payload, 2); i++) begin
        sigs.drvClk.din[tr.sa] <= datum[i];
        sigs.drvClk.valid_n[tr.sa] <= 1'b0;
        sigs.drvClk.frame_n[tr.sa] <= ((tr.payload.size() - 1) == index) && (i==7);
        @(sigs.drvClk);
      end
    end
    sigs.drvClk.valid_n[tr.sa] <= 1'b1;
  endtask
endclass: driver
`endif
