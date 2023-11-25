`ifndef RAL_HOST_REGMODEL
`define RAL_HOST_REGMODEL

import uvm_pkg::*;

class ral_reg_HOST_ID extends uvm_reg;
	uvm_reg_field REV_ID;
	uvm_reg_field CHIP_ID;

	function new(string name = "HOST_ID");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.REV_ID = uvm_reg_field::type_id::create("REV_ID");
      this.REV_ID.configure(this, 8, 0, "RO", 0, 8'h03, 1, 0, 1);
      this.CHIP_ID = uvm_reg_field::type_id::create("CHIP_ID");
      this.CHIP_ID.configure(this, 8, 8, "RO", 0, 8'h5A, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_HOST_ID)

endclass : ral_reg_HOST_ID


class ral_reg_PORT_LOCK extends uvm_reg;
	rand uvm_reg_field LOCK;

	function new(string name = "PORT_LOCK");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.LOCK = uvm_reg_field::type_id::create("LOCK");
      this.LOCK.configure(this, 16, 0, "W1C", 0, 16'hffff, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_PORT_LOCK)

endclass : ral_reg_PORT_LOCK


class ral_reg_REG_ARRAY extends uvm_reg;
	rand uvm_reg_field USER_REG;

	function new(string name = "REG_ARRAY");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.USER_REG = uvm_reg_field::type_id::create("USER_REG");
      this.USER_REG.configure(this, 16, 0, "RW", 0, 16'h0, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_REG_ARRAY)

endclass : ral_reg_REG_ARRAY


class ral_mem_RAM extends uvm_mem;
   function new(string name = "RAM");
      super.new(name, `UVM_REG_ADDR_WIDTH'h1000, 16, "RW", build_coverage(UVM_NO_COVERAGE));
   endfunction
   virtual function void build();
   endfunction: build

   `uvm_object_utils(ral_mem_RAM)

endclass : ral_mem_RAM


class ral_block_host_regmodel extends uvm_reg_block;
	rand ral_reg_HOST_ID HOST_ID;
	rand ral_reg_PORT_LOCK PORT_LOCK;
	rand ral_reg_REG_ARRAY REG_ARRAY[256];
	rand ral_mem_RAM RAM;
	uvm_reg_field HOST_ID_REV_ID;
	uvm_reg_field REV_ID;
	uvm_reg_field HOST_ID_CHIP_ID;
	uvm_reg_field CHIP_ID;
	rand uvm_reg_field PORT_LOCK_LOCK;
	rand uvm_reg_field LOCK;
	rand uvm_reg_field REG_ARRAY_USER_REG[256];
	rand uvm_reg_field USER_REG[256];

	function new(string name = "host_regmodel");
		super.new(name, build_coverage(UVM_NO_COVERAGE));
	endfunction: new

   virtual function void build();
      this.default_map = create_map("", 0, 2, UVM_LITTLE_ENDIAN);
      this.HOST_ID = ral_reg_HOST_ID::type_id::create("HOST_ID");
      this.HOST_ID.build();
      this.HOST_ID.configure(this, null, "");
         this.HOST_ID.add_hdl_path('{

            '{"host_id", -1, -1}
         });
      this.default_map.add_reg(this.HOST_ID, `UVM_REG_ADDR_WIDTH'h0, "RW", 0);
		this.HOST_ID_REV_ID = this.HOST_ID.REV_ID;
		this.REV_ID = this.HOST_ID.REV_ID;
		this.HOST_ID_CHIP_ID = this.HOST_ID.CHIP_ID;
		this.CHIP_ID = this.HOST_ID.CHIP_ID;
      this.PORT_LOCK = ral_reg_PORT_LOCK::type_id::create("PORT_LOCK");
      this.PORT_LOCK.build();
      this.PORT_LOCK.configure(this, null, "");
         this.PORT_LOCK.add_hdl_path('{

            '{"lock", -1, -1}
         });
      this.default_map.add_reg(this.PORT_LOCK, `UVM_REG_ADDR_WIDTH'h100, "RW", 0);
		this.PORT_LOCK_LOCK = this.PORT_LOCK.LOCK;
		this.LOCK = this.PORT_LOCK.LOCK;
      foreach (this.REG_ARRAY[i]) begin
         int J = i;
         this.REG_ARRAY[J] = ral_reg_REG_ARRAY::type_id::create($psprintf("REG_ARRAY[%0d]",J));
         this.REG_ARRAY[J].build();
         this.REG_ARRAY[J].configure(this, null, "");
         this.REG_ARRAY[J].add_hdl_path('{

            '{$psprintf("host_reg[%0d]", J), -1, -1}
         });
         this.default_map.add_reg(this.REG_ARRAY[J], `UVM_REG_ADDR_WIDTH'h1000+J*`UVM_REG_ADDR_WIDTH'h1, "RW", 0);
			this.REG_ARRAY_USER_REG[J] = this.REG_ARRAY[J].USER_REG;
			this.USER_REG[J] = this.REG_ARRAY[J].USER_REG;
      end
      this.RAM = ral_mem_RAM::type_id::create("RAM");
      this.RAM.build();
      this.RAM.configure(this, "ram");
      this.default_map.add_mem(this.RAM, `UVM_REG_ADDR_WIDTH'h4000, "RW", 0);
   endfunction : build

	`uvm_object_utils(ral_block_host_regmodel)

endclass : ral_block_host_regmodel



`endif
