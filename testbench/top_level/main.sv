`timescale 1ns/1ps

`include "gn4124_bfm.svh"
`include "if_wb_master.svh"
`include "if_wb_slave.svh"
`include "wb_packet_source.svh"
`include "wb_packet_sink.svh"
`include "endpoint_phy_wrapper.svh"
`include "nic_regs.vh"
`include "vic_regs.vh"
`include "dio_regs.vh"
`include "endpoint_regs.v"



const uint64_t BASE_WRPC = 'h0080000;
const uint64_t BASE_EP	= 'h00a0100;
const uint64_t BASE_NIC =  'h00c0000;
const uint64_t BASE_VIC =  'h00e0000;
const uint64_t BASE_TXTSU ='h00e1000;
const uint64_t BASE_DIO =  'h00e2300;

module main;
   reg clk_125m_pllref = 0;
   reg clk_20m_vcxo = 0;
//   reg clk_sys = 0;
   reg rst_n = 0;
   
   always #4ns clk_125m_pllref <= ~clk_125m_pllref;
//   always #8ns clk_sys <= ~clk_sys;
   always #20ns clk_20m_vcxo <= ~clk_20m_vcxo;

   initial #200ns rst_n = 1;
   
   

   
   IGN4124PCIMaster I_Gennum ();

   reg [4:0] dio_in = 0;
   
   wr_nic_sdb_top
	 	#(
			.g_simulation(1))
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

   IWishboneMaster 
     #(
       .g_data_width(16),
       .g_addr_width(2))
   U_wrf_source
     (
      .clk_i(DUT.clk_sys),
      .rst_n_i(rst_n)
      );

   IWishboneSlave
     #(
       .g_data_width(16),
       .g_addr_width(2))
   U_wrf_sink
     (
      .clk_i(DUT.clk_sys),
      .rst_n_i(rst_n)
      );

   
   IWishboneMaster 
     #(
       .g_data_width(32),
       .g_addr_width(7))
   U_sys_bus_master
     (
      .clk_i(DUT.clk_sys),
      .rst_n_i(rst_n)
      );


/* -----\/----- EXCLUDED -----\/-----*/
   endpoint_phy_wrapper
     #(
       .g_phy_type("GTP")) 
   U_Wrapped_EP_GTP
     (
      .clk_sys_i(DUT.clk_sys),
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
/* -----/\----- EXCLUDED -----/\----- */


//    task automatic tx_test(int n_tries, int is_q, int unvid, EthPacketSource src, EthPacketSink sink);
//      EthPacketGenerator gen = new;
//      EthPacket pkt, tmpl, pkt2;
//      EthPacket arr[];
//      int i;
//      
//      arr            = new[n_tries](arr);
//      
//  
//      tmpl           = new;
//      tmpl.src       = '{1,2,3,4,5,6};
//      tmpl.dst       = '{'h00, 'h50, 'hca, 'hfe, 'hba, 'hbe};
//      tmpl.has_smac  = 1;
//      tmpl.is_q      = is_q;
//      tmpl.vid       = 100;
//      tmpl.ethertype = 'h88f7;
//  // 
//      gen.set_randomization(EthPacketGenerator::SEQ_PAYLOAD /* | EthPacketGenerator::TX_OOB*/) ;
//      gen.set_template(tmpl);
//      gen.set_size(64,64);
//
//      for(i=0;i<n_tries;i++)
//           begin
//              pkt  = gen.gen();
//          //    $display("Tx %d", i);
//              //   pkt.dump();
//              src.send(pkt);
//	  //    $display("Send: %d [dsize %d]", i+1,pkt.payload.size() + 14);
//	      
//              arr[i]  = pkt;
//           end
//
//         for(i=0;i<n_tries;i++)
//           begin
//           sink.recv(pkt2);
////	      $display("rx %d", i);
//              
//           if(unvid)
//             arr[i].is_q  = 0;
//           
//           if(!arr[i].equal(pkt2))
//             begin
//                $display("Fault at %d", i);
//                
//                arr[i].dump();
//                pkt2.dump();
//                $stop;
//             end
//           end // for (i=0;i<n_tries;i++)
//      
//   endtask // tx_test


   task send_random(WBPacketSource src, int t);
      EthPacketGenerator gen = new;
      EthPacket pkt, tmpl;
      
      tmpl           = new;
			if(t==0) begin
      	tmpl.dst       = '{'h01, 'h1b, 'h19, 'h00, 'h00, 'h00};
      	tmpl.ethertype = 'h88f7;
			end;

			if(t==1) begin
      	tmpl.dst       = '{'hff, 'hff, 'hff, 'hff, 'hff, 'hff};
      	tmpl.ethertype = 'hdbff;
			end;

			if(t==2) begin
      	tmpl.dst       = '{'hff, 'hff, 'hff, 'hff, 'hff, 'hff};
      	tmpl.ethertype = 'h0800;
			end;

      tmpl.src       = '{'h3c,'h97,'h0e, 'h7a, 'ha3, 'h79};
      //tmpl.dst       = '{'h00, 'h50, 'hca, 'hfe, 'hba, 'hbe};
      tmpl.has_smac  = 1;
      tmpl.vid       = 100;
      //tmpl.ethertype = 'h0806;
			//tmpl.payload = '{'h00, 'h01, 'h08, 'h00, 'h06, 'h04, 'h00, 'h01, 'h3c,
			//'h97, 'h0e, 'h7a, 'ha3, 'h79, 'hc0, 'ha8, 'h05, 'h01, 'h00, 'h00, 'h00,
			//'h00, 'h00, 'h00, 'hc0, 'ha8, 'h05, 'h02};

      gen.set_randomization(EthPacketGenerator::SEQ_PAYLOAD /* | EthPacketGenerator::TX_OOB*/) ;
			//gen.set_randomization(0);
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
//      EthPacket pkt;
      CBusAccessor acc ;
      
      int i;

      acc = I_Gennum.get_accessor();
			acc.set_default_xfer_size(4);
      
      $display("GnPreReady\n");
               @(posedge I_Gennum.ready);
      $display("GnReady\n");

      #5us;

      //acc.write('h20510, 'ha5);

//      acc.write(BASE_EP + `ADDR_EP_ECR, `EP_ECR_TX_EN | `EP_ECR_RX_EN);
//      acc.write(BASE_EP + `ADDR_EP_RFCR, 1518 << `EP_RFCR_MRU_OFFSET);
//      acc.write(BASE_EP + `ADDR_EP_VCR0, 3 << `EP_VCR0_QMODE_OFFSET);
//      acc.write(BASE_EP + `ADDR_EP_TSCR, `EP_TSCR_EN_RXTS);


      
			$display(BASE_NIC + `ADDR_NIC_CR);
			$display(`NIC_CR_RX_EN | `NIC_CR_TX_EN);
      acc.write(BASE_NIC + `ADDR_NIC_CR, `NIC_CR_RX_EN | `NIC_CR_TX_EN);
      acc.write(BASE_NIC + `ADDR_NIC_EIC_IER, 'h7);
      acc.write(BASE_NIC + `BASE_NIC_DRX + 8, (1000) << 16);
      acc.write(BASE_NIC + `BASE_NIC_DRX + 0, 1);

      acc.write(BASE_VIC + `ADDR_VIC_CTL, `VIC_CTL_ENABLE | `VIC_CTL_EMU_EDGE | (100<<3));
      acc.write(BASE_VIC + `ADDR_VIC_IER, 'hff);
      acc.write(BASE_VIC + `ADDR_VIC_SWIR, 'h1);
      #1us;
      acc.write(BASE_VIC + `ADDR_VIC_EOIR, 'h1);
      

      #5us;

      //$stop;
      
      

//      #150us;
//
//      $display("ConfigDIO");
//
//      
//      acc.write(BASE_DIO + `ADDR_DIO_TRIG0, 0);
//      acc.write(BASE_DIO + `ADDR_DIO_TRIGH0, 0);
//      acc.write(BASE_DIO + `ADDR_DIO_CYC0, 'h3000);
//      acc.write(BASE_DIO + `ADDR_DIO_OUT, 'h01);
//      acc.write(BASE_DIO + `ADDR_DIO_PROG0_PULSE, 'h10);
//      acc.write(BASE_DIO + `ADDR_DIO_LATCH, 'h1);
//      acc.write(BASE_DIO + `ADDR_DIO_EIC_IER, 'hff);
//
//      #100us;
//      dio_in[0] = 1'b1;
//      #100ns;
//      dio_in[0] = 1'b0;
//
//      

      
//      @(posedge rst_n);
      @(posedge DUT.clk_sys);
      

      $display("EPInit!\n");

      
      sys_bus                                 = U_sys_bus_master.get_accessor();
      sys_bus.set_mode(CLASSIC);
      sys_bus.write(`ADDR_EP_ECR, `EP_ECR_TX_EN | `EP_ECR_RX_EN);
      sys_bus.write(`ADDR_EP_RFCR, 1518 << `EP_RFCR_MRU_OFFSET);
      sys_bus.write(`ADDR_EP_VCR0, 3 << `EP_VCR0_QMODE_OFFSET);
      sys_bus.write(`ADDR_EP_TSCR, `EP_TSCR_EN_RXTS);


      

      #300us;


// TEST RX PATH
      forever begin
				 uint64_t ret;	
         send_random(src, 0);
         #10us;
         send_random(src, 1);
				 #5us;
				 acc.read(BASE_NIC + `BASE_NIC_DRX, ret);
				 acc.read(BASE_NIC + `BASE_NIC_DRX + 4, ret);
				 acc.read(BASE_NIC + `BASE_NIC_DRX + 8, ret);
         #5us;
         send_random(src, 2);
				 #10us;
      end

// TEST TX PATH (quick and messy, we need nice code here)
//			forever begin
//				acc.write(BASE_NIC + 'h8000, 'hffffffff);
//				acc.write(BASE_NIC + 'h8004, 'hffff3c97);
//				acc.write(BASE_NIC + 'h8008, 'h0e7aa379);
//				acc.write(BASE_NIC + 'h800c, 'hdbff0001);
//				acc.write(BASE_NIC + 'h8010, 'h02030405);
//				acc.write(BASE_NIC + 'h8014, 'h06070809);
//				acc.write(BASE_NIC + 'h8018, 'h0a0b0c0d);
//				acc.write(BASE_NIC + 'h801c, 'h0e0f1011);
//				acc.write(BASE_NIC + 'h8020, 'h12131415);
//				acc.write(BASE_NIC + 'h8024, 'h16171819);
//				acc.write(BASE_NIC + 'h8028, 'h1a1b1c1d);
//				acc.write(BASE_NIC + 'h802c, 'h1e1f2021);
//				acc.write(BASE_NIC + 'h8030, 'h22232425);
//				acc.write(BASE_NIC + 'h8034, 'h26272829);
//				acc.write(BASE_NIC + 'h8038, 'h2a2b2c2d);
//				acc.write(BASE_NIC + 'h803c, 'h2e2f3031);
//				acc.write(BASE_NIC + 'h8040, 'h32333435);
//				acc.write(BASE_NIC + 'h8044, 'h36373839);
//				acc.write(BASE_NIC + 'h8048, 'h3a3b3c3d);
//				acc.write(BASE_NIC + 'h804c, 'h3e3f4041);
//
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+4, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+8, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+14, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+18, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+10, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+24, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+28, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+20, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+34, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+38, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+30, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+44, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+48, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+40, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//				///////////////////////////////////////////////////////
//				acc.write(BASE_NIC + `BASE_NIC_DTX+54, 'h00400000);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+58, 'h1);
//				acc.write(BASE_NIC + `BASE_NIC_DTX+50, 'h12340001);
//				#2us;
//				//acc.write(BASE_NIC + `ADDR_NIC_SR, 'h4);
//				//acc.write(BASE_NIC + `ADDR_NIC_EIC_ISR, 'h2);
//				#8us;
//			end
      
      
   end
   
   
endmodule // main
