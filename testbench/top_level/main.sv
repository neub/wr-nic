`timescale 1ns/1ps

`include "gn4124_bfm.svh"
`include "if_wb_master.svh"
`include "if_wb_slave.svh"
`include "drivers/simdrv_wrsw_nic.svh"
`include "endpoint_regs.v"
`include "endpoint_mdio.v"
`include "regs/dio_regs.vh"
`include "regs/vic_regs.vh"

`include "endpoint_phy_wrapper.svh"


const uint64_t BASE_WRPC = 'h0080000;
const uint64_t BASE_NIC =  'h00c0000;
const uint64_t BASE_VIC =  'h00e0000;
const uint64_t BASE_TXTSU ='h00e1000;
const uint64_t BASE_DIO =  'h00e2300;

module main;
   reg clk_125m_pllref = 0;
   reg clk_20m_vcxo = 0;
   reg clk_sys = 0;
   reg rst_n = 0;
   
   always #4ns clk_125m_pllref <= ~clk_125m_pllref;
   always #8ns clk_sys <= ~clk_sys;
   always #20ns clk_20m_vcxo <= ~clk_20m_vcxo;

   initial #200ns rst_n = 1;
   
   
   IWishboneMaster 
     #(
       .g_data_width(16),
       .g_addr_width(2))
   U_wrf_source
     (
      .clk_i(clk_sys),
      .rst_n_i(rst_n)
      );

   IWishboneSlave
     #(
       .g_data_width(16),
       .g_addr_width(2))
   U_wrf_sink
     (
      .clk_i(clk_sys),
      .rst_n_i(rst_n)
      );

   
   IWishboneMaster 
     #(
       .g_data_width(32),
       .g_addr_width(7))
   U_sys_bus_master
     (
      .clk_i(clk_sys),
      .rst_n_i(rst_n)
      );


/* -----\/----- EXCLUDED -----\/-----
   endpoint_phy_wrapper
     #(
       .g_phy_type("GTP")) 
   U_Wrapped_EP_GTP
     (
      .clk_sys_i(clk_sys),
      .clk_ref_i(clk_125m_pllref),    
      .clk_rx_i(clk_125m_pllref),
      .rst_n_i(rst_n),

      .snk (U_wrf_sink.slave),
      .src(U_wrf_source.master),
      .sys(U_sys_bus_master.master),

      .txn_o(rxn),
      .txp_o(rxp),

      .rxn_i(txn),
      .rxp_i(txp)
      );
 -----/\----- EXCLUDED -----/\----- */

   
   IGN4124PCIMaster I_Gennum ();

   reg [4:0] dio_in = 0;
   
   wr_nic_sdb_top
     DUT (
          .clk_125m_pllref_p_i(clk_125m_pllref),
          .clk_125m_pllref_n_i(~clk_125m_pllref),          

          . fpga_pll_ref_clk_101_p_i(clk_125m_pllref),
          . fpga_pll_ref_clk_101_n_i(~clk_125m_pllref),
          
          .clk_20m_vcxo_i(clk_20m_vcxo),

          `GENNUM_WIRE_SPEC_PINS(I_Gennum),

          .sfp_txp_o(txp),
          .sfp_txn_o(txn),

          .sfp_rxp_i(rxp),
          .sfp_rxn_i(rxn),

          .dio_n_i(~dio_in),
          .dio_p_i(dio_in)
	  );



    task automatic tx_test(int n_tries, int is_q, int unvid, EthPacketSource src, EthPacketSink sink);
      EthPacketGenerator gen = new;
      EthPacket pkt, tmpl, pkt2;
      EthPacket arr[];
      int i;
      
      arr            = new[n_tries](arr);
      
  
      tmpl           = new;
      tmpl.src       = '{1,2,3,4,5,6};
      tmpl.dst       = '{'h00, 'h50, 'hca, 'hfe, 'hba, 'hbe};
      tmpl.has_smac  = 1;
      tmpl.is_q      = is_q;
      tmpl.vid       = 100;
      tmpl.ethertype = 'h88f7;
  // 
      gen.set_randomization(EthPacketGenerator::SEQ_PAYLOAD /* | EthPacketGenerator::TX_OOB*/) ;
      gen.set_template(tmpl);
      gen.set_size(64,64);

      for(i=0;i<n_tries;i++)
           begin
              pkt  = gen.gen();
          //    $display("Tx %d", i);
              //   pkt.dump();
              src.send(pkt);
	  //    $display("Send: %d [dsize %d]", i+1,pkt.payload.size() + 14);
	      
              arr[i]  = pkt;
           end

         for(i=0;i<n_tries;i++)
           begin
           sink.recv(pkt2);
//	      $display("rx %d", i);
              
           if(unvid)
             arr[i].is_q  = 0;
           
           if(!arr[i].equal(pkt2))
             begin
                $display("Fault at %d", i);
                
                arr[i].dump();
                pkt2.dump();
                $stop;
             end
           end // for (i=0;i<n_tries;i++)
      
   endtask // tx_test


   task send_random(WBPacketSource src);
      EthPacketGenerator gen = new;
      EthPacket pkt, tmpl;
      
      tmpl           = new;
      tmpl.src       = '{1,2,3,4,5,6};
      tmpl.dst       = '{'h00, 'h50, 'hca, 'hfe, 'hba, 'hbe};
      tmpl.has_smac  = 1;
      tmpl.vid       = 100;
      tmpl.ethertype = 'h88f7;

      gen.set_randomization(EthPacketGenerator::SEQ_PAYLOAD /* | EthPacketGenerator::TX_OOB*/) ;
      gen.set_template(tmpl);
      gen.set_size(64,64);

      pkt = gen.gen();
      src.send(pkt);

   endtask // send_random
   
   initial begin
/*
       uint64_t rval;
      int i;
      NICPacketSource nic_src;
      NICPacketSink nic_snk;
      CSimDrv_NIC drv;
      
      acc = I_Gennum.get_accessor();
      @(posedge I_Gennum.ready);
      drv = new (acc, BASE_NIC);
      drv.init();
      nic_src = new (drv);
      nic_snk = new (drv);      
 */
      CWishboneAccessor sys_bus;
      WBPacketSource src  = new(U_wrf_source.get_accessor());
      WBPacketSink sink   = new(U_wrf_sink.get_accessor()); 
//      CSimDrv_WR_Endpoint ep_drv;
      EthPacket pkt;
      CBusAccessor acc ;
      
      int i;

      acc = I_Gennum.get_accessor();
      
      $display("GnPreReady\n");
               @(posedge I_Gennum.ready);
      $display("GnReady\n");

      
      acc.write(BASE_NIC + `ADDR_NIC_CR, `NIC_CR_RX_EN | `NIC_CR_TX_EN);
      acc.write(BASE_NIC + `ADDR_NIC_EIC_IER, 'h7);
      acc.write(BASE_NIC + `BASE_NIC_DRX + 8, (1000) << 16);
      acc.write(BASE_NIC + `BASE_NIC_DRX + 0, 1);

      acc.write(BASE_VIC + `ADDR_VIC_CTL, `VIC_CTL_ENABLE | `VIC_CTL_EMU_EDGE | (100<<3));
      acc.write(BASE_VIC + `ADDR_VIC_IER, 'hff);
      acc.write(BASE_VIC + `ADDR_VIC_SWIR, 'h1);
      #1us;
      acc.write(BASE_VIC + `ADDR_VIC_EOIR, 'h1);
      

      #1us;

      $stop;
      
      

      #150us;

      $display("ConfigDIO");

      
      acc.write(BASE_DIO + `ADDR_DIO_TRIG0, 0);
      acc.write(BASE_DIO + `ADDR_DIO_TRIGH0, 0);
      acc.write(BASE_DIO + `ADDR_DIO_CYC0, 'h3000);
      acc.write(BASE_DIO + `ADDR_DIO_OUT, 'h01);
      acc.write(BASE_DIO + `ADDR_DIO_PROG0_PULSE, 'h10);
      acc.write(BASE_DIO + `ADDR_DIO_LATCH, 'h1);
      acc.write(BASE_DIO + `ADDR_DIO_EIC_IER, 'hff);

      #100us;
      dio_in[0] = 1'b1;
      #100ns;
      dio_in[0] = 1'b0;

      

      
//      @(posedge rst_n);
      @(posedge clk_sys);
      

      $display("EPInit!\n");

      
      sys_bus                                 = U_sys_bus_master.get_accessor();
      
      sys_bus.set_mode(CLASSIC);
      sys_bus.write(`ADDR_EP_ECR, `EP_ECR_TX_EN | `EP_ECR_RX_EN);
      sys_bus.write(`ADDR_EP_RFCR, 1518 << `EP_RFCR_MRU_OFFSET);
      sys_bus.write(`ADDR_EP_VCR0, 3 << `EP_VCR0_QMODE_OFFSET);
      sys_bus.write(`ADDR_EP_TSCR, `EP_TSCR_EN_RXTS);


      

      #700us;
      
      forever begin
         send_random(src);
         #1us;
      end
      
      
   end
   
   
endmodule // main
