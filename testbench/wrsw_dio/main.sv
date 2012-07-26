`timescale 1ns/1ps

`include "tbi_utils.sv"
   
`include "simdrv_defs.svh"
`include "if_wb_master.svh"

module main;

   wire clk_ref;
   wire clk_sys;
   wire rst_n;

   wire clk_sys_dly;
   wire time_valid;

   IWishboneMaster WB (
      .clk_i(clk_sys),
      .rst_n_i(rst_n)); 
   
  tbi_clock_rst_gen
     #(
       .g_rbclk_period(8000))  
  clkgen( 
	.clk_ref_o(clk_ref),
	.clk_sys_o(clk_sys),
	.rst_n_o(rst_n));


   assign  #10 clk_sys_dly  = clk_sys;
   assign  #1  time_valid =1'b1;
  
   wrsw_dio 
      #(
        .g_interface_mode(PIPELINED),
        .g_address_granularity(BYTE)) 
    DUT(
      .clk_sys_i (clk_sys),
      .clk_ref_i (clk_ref),
      .rst_n_i   (rst_n),

      .tm_time_valid_i(time_valid),

      .wb_cyc_i  (WB.master.cyc),
      .wb_stb_i  (WB.master.stb),
      .wb_we_i   (WB.master.we),
      .wb_sel_i  (4'b1111),
      .wb_adr_i  (WB.master.adr[31:0]),
      .wb_dat_i  (WB.master.dat_o),
      .wb_dat_o  (WB.master.dat_i),
      .wb_ack_o  (WB.master.ack),
      .wb_stall_o(WB.master.stall)
    );


   initial begin
      CWishboneAccessor acc;
      uint64_t data;

      @(posedge rst_n);
      repeat(3) @(posedge clk_sys);

      #1us;
            
      acc  = WB.get_accessor();
      acc.set_mode(PIPELINED);
      
     #1us;
      acc.write(32'h00000000, 'hdeadbeef);
      //acc.write(32'h00008000, 'hdeadbeef);

      //#1us;
      acc.write(32'h00000004, 'hcafebabe);
      //acc.write(32'h00008004, 'hcafebabe);

 /*     acc.read(32'h00000000, data);
      acc.read(32'h00000004, data);
      //acc.read(32'h00008000, data);
      //acc.read(32'h00008004, data);

      acc.write(32'h0000004c, 'habcdef00);
      acc.read(32'h00000004c, data);     */
      
   end
   
   
endmodule // main

