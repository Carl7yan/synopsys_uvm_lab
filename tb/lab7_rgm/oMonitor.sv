`ifndef OMONITOR__SV
`define OMONITOR__SV

class oMonitor extends uvm_monitor;
  int port_id = -1;
  virtual router_io sigs;
  uvm_analysis_port #(packet) analysis_port;

  `uvm_component_utils_begin(oMonitor)
    `uvm_field_int(port_id, UVM_DEFAULT | UVM_DEC)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual router_io)::get(this, "", "router_io", sigs)) begin
      `uvm_fatal("CFGERR", "oMonitor DUT interface not set");
    end
    analysis_port = new("analysis_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    packet tr;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    forever begin
      tr = packet::type_id::create("tr", this);
      tr.da = this.port_id;
      this.get_packet(tr);
      `uvm_info("Got Output Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
      analysis_port.write(tr);
    end
  endtask

  task get_packet(packet tr);
    logic [7:0] datum;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    @(negedge sigs.oMonClk.frameo_n[port_id]);

    forever begin
      for(int i=0; i<8; i=i) begin
        if (!sigs.oMonClk.valido_n[port_id]) begin
          datum[i++] = sigs.oMonClk.dout[port_id];
          if (i == 8) begin
            tr.payload.push_back(datum);
          end
          if (sigs.oMonClk.frameo_n[port_id]) begin
            if (i == 8) begin
              return;
            end else begin
              `uvm_fatal("Payload Error", "Not byte aligned");
            end
          end
        end
        @(sigs.oMonClk);
      end
    end
  endtask: get_packet

endclass

`endif
