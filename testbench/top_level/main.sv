`timescale 1ns/1ps

`include "gn4124_bfm.svh"   

const uint64_t BASE_WRPC = 'h0080000;
const uint64_t BASE_NIC =  'h00c0000;
const uint64_t BASE_VIC =  'h00e0000;
const uint64_t BASE_TXTSU ='h00e1000;
const uint64_t BASE_DIO =  'h00e2000;


module main;
   reg clk_125m_pllref = 0;
   reg clk_20m_vcxo = 0;
   
   always #4ns clk_125m_pllref <= ~clk_125m_pllref;
   always #20ns clk_20m_vcxo <= ~clk_20m_vcxo;
   
   IGN4124PCIMaster I_Gennum ();

   wr_nic_sdb_top
     DUT (
          .clk_125m_pllref_p_i(clk_125m_pllref),
          .clk_125m_pllref_n_i(~clk_125m_pllref),
          .clk_20m_vcxo_i(clk_20m_vcxo),

          `GENNUM_WIRE_SPEC_PINS(I_Gennum)
	  );

   initial begin
      uint64_t rval;
      
      CBusAccessor acc ;
      acc = I_Gennum.get_accessor();
      @(posedge I_Gennum.ready);

      $display("Startup");

      acc.write('ha0400, 'h1deadbee); // reset lm32, h20004
      acc.write('ha0400, 'h0deadbee);      

      acc.write('hc0000, 'h0deadbee);      
      acc.write('he0000, 'h0deadbee);      
      acc.write('he1000, 'h0deadbee);      
      acc.write('he2000, 'h0deadbee);      
      
      acc.write(BASE_WRPC + 'h100, 'hdeadbeef);
      acc.write(BASE_WRPC + 'h104, 'hcafebabe);

      $display("AccWriteDone");
      

      acc.read(BASE_WRPC + 'h100, rval);
      $display("MemReadback1 %x", rval);
      acc.read(BASE_WRPC + 'h104, rval);
      //$display("MemReadback2 %x", rval);

/* -----\/----- EXCLUDED -----\/-----
      acc.write(BASE_VIC + 'h4, 'h1); // enable IRQ 0
      acc.write(BASE_VIC + 'h0, 'h3); // positive polarity, enable VIC
      acc.write(BASE_VIC + 'h18, 'h1); // software IRQ trigger
 -----/\----- EXCLUDED -----/\----- */

      
      
      
      
      
   end
   
   
endmodule // main



