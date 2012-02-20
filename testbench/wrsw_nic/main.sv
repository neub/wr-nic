`timescale 1ns/1ps

`include "tbi_utils.sv"
   
`include "simdrv_defs.svh"
`include "if_wb_master.svh"

module main;

   wire clk_ref;
   wire clk_sys;
   wire rst_n;

   IWishboneMaster WB (
      .clk_i(clk_sys),
      .rst_n_i(rst_n)); 
   tbi_clock_rst_gen
     #(
       .g_rbclk_period(8000))
     clkgen(
	    .clk_ref_o(clk_ref),
	    .clk_sys_o(clk_sys),
	    .rst_n_o(rst_n)
	    );

   wire clk_sys_dly;

   assign  #10 clk_sys_dly  = clk_sys;
  
    wrsw_nic #(
      .g_USE_DMA    (1)
    )
    DUT (
	    .clk_sys_i      (clk_sys),
    	.rst_n_i        (rst_n),

      //.wb_cyc_i  (WB.master.cyc),
      //.wb_stb_i  (WB.master.stb),
      //.wb_we_i   (WB.master.we),
      //.wb_sel_i  (4'b1111),
      //.wb_adr_i  (WB.master.adr[31:0]),
      //.wb_dat_i  (WB.master.dat_o),
      //.wb_dat_o  (WB.master.dat_i),
      //.wb_ack_o  (WB.master.ack),
      //.wb_stall_o(WB.master.stall)

      .dma_cyc_i  (WB.master.cyc),
      .dma_stb_i  (WB.master.stb),
      .dma_we_i   (WB.master.we),
      .dma_sel_i  (4'b1111),
      .dma_adr_i  (WB.master.adr[31:0]),
      .dma_dat_i  (WB.master.dat_o),
      .dma_dat_o  (WB.master.dat_i),
      .dma_ack_o  (WB.master.ack),
      .dma_stall_o(WB.master.stall)
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

      acc.read(32'h00000000, data);
      acc.read(32'h00000004, data);
      //acc.read(32'h00008000, data);
      //acc.read(32'h00008004, data);


      
      
   end
   
   
endmodule // main

