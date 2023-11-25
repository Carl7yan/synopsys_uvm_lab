`ifndef IMONITOR__SV
`define IMONITOR__SV

class iMonitor extends uvm_monitor;
  virtual router_io sigs;
  int port_id = -1;

  uvm_analysis_port #(packet) analysis_port;

  `uvm_component_utils_begin(iMonitor)
    `uvm_field_int(port_id, UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (!uvm_config_db#(int)::get(this, "", "port_id", port_id)) begin
      `uvm_fatal("CFGERR", "iMonitor port_id not set");
    end
    if (!uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs)) begin
      `uvm_fatal("CFGERR", "iMonitor DUT interface not set");
    end

    analysis_port = new("analysis_port", this);
  endfunction

  virtual task run_phase (uvm_phase phase);
    packet tr;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    forever begin
      tr = packet::type_id::create("tr", this);
      tr.sa = this.port_id;
      get_packet(tr);
      `uvm_info("Got Input Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
      analysis_port.write(tr);
    end
  endtask

  virtual task get_packet(packet tr);
    logic [7:0] datum;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    @(negedge sigs.iMonClk.frame_n[port_id]);
    for (int i=0; i<4; i++) begin
      if (!sigs.iMonClk.frame_n[port_id]) begin
        tr.da[i] = sigs.iMonClk.din[port_id];
        // the da field is populated here
      end else begin
        `uvm_fatal("Header Error", $sformatf("@ Header cycle %0d, Frame not zero", i));
      end
      @(sigs.iMonClk);
    end

    for (int i=0; i<5; i++) begin
      if (!sigs.iMonClk.frame_n[port_id]) begin
        if (sigs.iMonClk.valid_n[port_id] && sigs.iMonClk.din[port_id]) begin
          @(sigs.iMonClk);
          continue;
        end else begin
          `uvm_fatal("Header Error", $sformatf("@%0d Valid or Din zero", i));
        end
      end else begin
        `uvm_fatal("Header Error", "Frame not zero");
      end
    end

    forever begin
      for(int i=0; i<8; i=i) begin
        if (!sigs.iMonClk.valid_n[port_id]) begin
          if (sigs.iMonClk.busy_n[port_id]) begin
            datum[i++] = sigs.iMonClk.din[port_id];
            if (i == 8) begin
              tr.payload.push_back(datum);
              // the payload is populated here
            end
          end else begin
            `uvm_fatal("Payload Error", "Busy & Valid conflict");
          end
        end
        if (sigs.iMonClk.frame_n[port_id]) begin
          if (i == 8) begin
            return;
          end else begin
            `uvm_fatal("Payload Error", "Not byte aligned");
          end
        end
        @(sigs.iMonClk);
      end
    end
  endtask: get_packet

endclass
`endif
