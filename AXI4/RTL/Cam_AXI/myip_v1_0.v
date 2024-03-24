
`timescale 1 ns / 1 ps

module myip_v1_0 #
(
	parameter  		  	C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
	parameter integer 	C_M00_AXI_BURST_LEN					= 128		,
	parameter integer 	C_M00_AXI_ID_WIDTH					= 1			,
	parameter integer 	C_M00_AXI_ADDR_WIDTH				= 32		,
	parameter integer 	C_M00_AXI_DATA_WIDTH				= 32		,
	parameter integer 	C_M00_AXI_AWUSER_WIDTH				= 0			,
	parameter integer 	C_M00_AXI_ARUSER_WIDTH				= 0			,
	parameter integer 	C_M00_AXI_WUSER_WIDTH				= 0			,
	parameter integer 	C_M00_AXI_RUSER_WIDTH				= 0			,
	parameter integer 	C_M00_AXI_BUSER_WIDTH				= 0
)
(
	// data from camera
	input										cam_data_asy_rst  		,
	input										cam_frame_vsync   		,
	input										cam_frame_href    		,
	input										cam_frame_valid   		,
	input	[15:0]								cam_frame_data    		,
	input										cam_frame_dclk    		,
	// Ports of Axi Master Bus Interface M00_AXI
	input                                       m00_axi_init_axi_txn    ,
	output                                      m00_axi_txn_done        ,
	output                                      m00_axi_error           ,
	input                                       m00_axi_aclk            ,
	input                                       m00_axi_aresetn         ,
	output  [C_M00_AXI_ID_WIDTH-1 : 0]          m00_axi_awid            ,
	output  [C_M00_AXI_ADDR_WIDTH-1 : 0]        m00_axi_awaddr          ,
	output  [7 : 0]                             m00_axi_awlen           ,
	output  [2 : 0]                             m00_axi_awsize          ,
	output  [1 : 0]                             m00_axi_awburst         ,
	output                                      m00_axi_awlock          ,
	output  [3 : 0]                             m00_axi_awcache         ,
	output  [2 : 0]                             m00_axi_awprot          ,
	output  [3 : 0]                             m00_axi_awqos           ,
	output  [C_M00_AXI_AWUSER_WIDTH-1 : 0]      m00_axi_awuser          ,
	output                                      m00_axi_awvalid         ,
	input                                       m00_axi_awready         ,
	output  [C_M00_AXI_DATA_WIDTH-1 : 0]        m00_axi_wdata           ,
	output  [C_M00_AXI_DATA_WIDTH/8-1 : 0]      m00_axi_wstrb           ,
	output                                      m00_axi_wlast           ,
	output  [C_M00_AXI_WUSER_WIDTH-1 : 0]       m00_axi_wuser           ,
	output                                      m00_axi_wvalid          ,
	input                                       m00_axi_wready          ,
	input   [C_M00_AXI_ID_WIDTH-1 : 0]          m00_axi_bid             ,
	input   [1 : 0]                             m00_axi_bresp           ,
	input   [C_M00_AXI_BUSER_WIDTH-1 : 0]       m00_axi_buser           ,
	input                                       m00_axi_bvalid          ,
	output                                      m00_axi_bready          ,
	output  [C_M00_AXI_ID_WIDTH-1 : 0]          m00_axi_arid            ,
	output  [C_M00_AXI_ADDR_WIDTH-1 : 0]        m00_axi_araddr          ,
	output  [7 : 0]                             m00_axi_arlen           ,
	output  [2 : 0]                             m00_axi_arsize          ,
	output  [1 : 0]                             m00_axi_arburst         ,
	output                                      m00_axi_arlock          ,
	output  [3 : 0]                             m00_axi_arcache         ,
	output  [2 : 0]                             m00_axi_arprot          ,
	output  [3 : 0]                             m00_axi_arqos           ,
	output  [C_M00_AXI_ARUSER_WIDTH-1 : 0]      m00_axi_aruser          ,
	output                                      m00_axi_arvalid         ,
	input                                       m00_axi_arready         ,
	input   [C_M00_AXI_ID_WIDTH-1 : 0]          m00_axi_rid             ,
	input   [C_M00_AXI_DATA_WIDTH-1 : 0]        m00_axi_rdata           ,
	input   [1 : 0]                             m00_axi_rresp           ,
	input                                       m00_axi_rlast           ,
	input   [C_M00_AXI_RUSER_WIDTH-1 : 0]       m00_axi_ruser           ,
	input                                       m00_axi_rvalid          ,
	output                                      m00_axi_rready           
);

/******************************************** Wire Define ****************************************************************/

	
wire									fifo_data_valid					;
wire									fifo_dbiterr					;
wire	[32:0]							fifo_dout						;
wire									fifo_empty						;
wire									fifo_full						;
wire									fifo_overflow					;
wire									fifo_prog_empty					;
wire									fifo_prog_full					;
wire									fifo_rd_data_count				;
wire									fifo_rd_rst_busy				;
wire									fifo_sbiterr					;
wire									fifo_underflow					;
wire									fifo_wr_ack						;
wire									fifo_wr_data_count				;
wire									fifo_wr_rst_busy				;
wire	[15:0]							fifo_din						;
wire									fifo_injectdbiterr				;
wire									fifo_injectsbiterr				;	
wire									fifo_rd_clk						;
wire									fifo_rd_en						;
wire									fifo_rst						;
wire									fifo_sleep						;
wire									fifo_wr_clk						;
wire									fifo_wr_en						;
	
wire	[C_M00_AXI_DATA_WIDTH-1:0]		data_fifor_axiw					;
wire									dvalid_fifor_axiw				;
wire									dfull_fifor_axiw				;
wire									dempty_fifor_axiw				;

/******************************************** Parameter Define ***********************************************************/
parameter 	integer		RD_DATA_COUNT_WIDTH	= $clog2(FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH) + 1;
parameter 	integer		FIFO_WRITE_DEPTH	= 1024;
parameter 	integer		WRITE_DATA_WIDTH	= 16;
parameter 	integer		READ_DATA_WIDTH		= C_M00_AXI_DATA_WIDTH;
parameter 	integer		WR_DATA_COUNT_WIDTH	= $clog2(FIFO_WRITE_DEPTH) + 1;
parameter 	integer		PROG_EMPTY_THRESH	= 5;
parameter 	integer		PROG_FULL_THRESH	= 992;

/******************************************** Instantiation **************************************************************/
// Instantiation of Axi Bus Interface M00_AXI	
myip_v1_0_M00_AXI #( 	
	.C_M_TARGET_SLAVE_BASE_ADDR		(C_M00_AXI_TARGET_SLAVE_BASE_ADDR)	,
	.C_M_AXI_BURST_LEN				(C_M00_AXI_BURST_LEN)				,
	.C_M_AXI_ID_WIDTH				(C_M00_AXI_ID_WIDTH)				,
	.C_M_AXI_ADDR_WIDTH				(C_M00_AXI_ADDR_WIDTH)				,
	.C_M_AXI_DATA_WIDTH				(C_M00_AXI_DATA_WIDTH)				,
	.C_M_AXI_AWUSER_WIDTH			(C_M00_AXI_AWUSER_WIDTH)			,
	.C_M_AXI_ARUSER_WIDTH			(C_M00_AXI_ARUSER_WIDTH)			,
	.C_M_AXI_WUSER_WIDTH			(C_M00_AXI_WUSER_WIDTH)				,
	.C_M_AXI_RUSER_WIDTH			(C_M00_AXI_RUSER_WIDTH)				,
	.C_M_AXI_BUSER_WIDTH			(C_M00_AXI_BUSER_WIDTH)		
) 	
myip_v1_0_M00_AXI_inst 	
(	
	.ERROR							(m00_axi_error)						,
	.M_AXI_ACLK						(m00_axi_aclk)						,
	.M_AXI_ARESETN					(m00_axi_aresetn)					,
	.M_AXI_AWID						(m00_axi_awid)						,
	.M_AXI_AWADDR					(m00_axi_awaddr)					,
	.M_AXI_AWLEN					(m00_axi_awlen)						,
	.M_AXI_AWSIZE					(m00_axi_awsize)					,
	.M_AXI_AWBURST					(m00_axi_awburst)					,
	.M_AXI_AWLOCK					(m00_axi_awlock)					,
	.M_AXI_AWCACHE					(m00_axi_awcache)					,
	.M_AXI_AWPROT					(m00_axi_awprot)					,
	.M_AXI_AWQOS					(m00_axi_awqos)						,
	.M_AXI_AWUSER					(m00_axi_awuser)					,
	.M_AXI_AWVALID					(m00_axi_awvalid)					,
	.M_AXI_AWREADY					(m00_axi_awready)					,
	.M_AXI_WDATA					(m00_axi_wdata)						,
	.M_AXI_WSTRB					(m00_axi_wstrb)						,
	.M_AXI_WLAST					(m00_axi_wlast)						,
	.M_AXI_WUSER					(m00_axi_wuser)						,
	.M_AXI_WVALID					(m00_axi_wvalid)					,
	.M_AXI_WREADY					(m00_axi_wready)					,
	.M_AXI_BID						(m00_axi_bid)						,
	.M_AXI_BRESP					(m00_axi_bresp)						,
	.M_AXI_BUSER					(m00_axi_buser)						,
	.M_AXI_BVALID					(m00_axi_bvalid)					,
	.M_AXI_BREADY					(m00_axi_bready)					,
	.M_AXI_ARID						(m00_axi_arid)						,
	.M_AXI_ARADDR					(m00_axi_araddr)					,
	.M_AXI_ARLEN					(m00_axi_arlen)						,
	.M_AXI_ARSIZE					(m00_axi_arsize)					,
	.M_AXI_ARBURST					(m00_axi_arburst)					,
	.M_AXI_ARLOCK					(m00_axi_arlock)					,
	.M_AXI_ARCACHE					(m00_axi_arcache)					,
	.M_AXI_ARPROT					(m00_axi_arprot)					,
	.M_AXI_ARQOS					(m00_axi_arqos)						,
	.M_AXI_ARUSER					(m00_axi_aruser)					,
	.M_AXI_ARVALID					(m00_axi_arvalid)					,
	.M_AXI_ARREADY					(m00_axi_arready)					,
	.M_AXI_RID						(m00_axi_rid)						,
	.M_AXI_RDATA					(m00_axi_rdata)						,
	.M_AXI_RRESP					(m00_axi_rresp)						,
	.M_AXI_RLAST					(m00_axi_rlast)						,
	.M_AXI_RUSER					(m00_axi_ruser)						,
	.M_AXI_RVALID					(m00_axi_rvalid)					,
	.M_AXI_RREADY					(m00_axi_rready)					,
	// user	
	.data_fifor_axiw				(data_fifor_axiw)					,
	.dvalid_fifor_axiw				(dvalid_fifor_axiw)					,
	.dfull_fifor_axiw				(dfull_fifor_axiw)					,
	.dempty_fifor_axiw				(dempty_fifor_axiw)
);

xpm_fifo_async #(
   	.CDC_SYNC_STAGES				(2)									,   // DECIMAL
   	.DOUT_RESET_VALUE				("0")								,   // String
   	.ECC_MODE						("no_ecc")							,   // String
   	.FIFO_MEMORY_TYPE				("auto")							, 	// String

   	.FIFO_WRITE_DEPTH				(FIFO_WRITE_DEPTH)					, 	// DECIMAL
   	.FULL_RESET_VALUE				(0)									,   // DECIMAL
   	.PROG_EMPTY_THRESH				(PROG_EMPTY_THRESH)					,   // DECIMAL
   	.PROG_FULL_THRESH				(PROG_FULL_THRESH)					,   // DECIMAL
   	.RD_DATA_COUNT_WIDTH			(RD_DATA_COUNT_WIDTH)				,   // DECIMAL
   	.READ_DATA_WIDTH				(READ_DATA_WIDTH)					,   // DECIMAL
   	.READ_MODE						("fwft")							,   // String
    .FIFO_READ_LATENCY				(0)									,   // DECIMAL
   	.RELATED_CLOCKS					(0)									,   // DECIMAL
  	//.SIM_ASSERT_CHK					(0)								,   // DECIMAL
   	.USE_ADV_FEATURES				("0707")							, 	// String
   	.WAKEUP_TIME					(0)									,   // DECIMAL
   	.WRITE_DATA_WIDTH				(WRITE_DATA_WIDTH)					,   // DECIMAL
   	.WR_DATA_COUNT_WIDTH			(WR_DATA_COUNT_WIDTH)   				// DECIMAL
)
xpm_fifo_async_inst (
	.almost_empty					()									,
	.almost_full					()									,
	.data_valid						(fifo_data_valid)					,
	.dbiterr						(fifo_dbiterr)						,
	.dout							(fifo_dout)							,
	.empty							(fifo_empty)						,
	.full							(fifo_full)							,
	.overflow						(fifo_overflow)						,
	.prog_empty						(fifo_prog_empty)					,
	.prog_full						(fifo_prog_full)					,
	.rd_data_count					(fifo_rd_data_count)				,
	.rd_rst_busy					(fifo_rd_rst_busy)					,
	.sbiterr						(fifo_sbiterr)						,
	.underflow						(fifo_underflow)					,
	.wr_ack							(fifo_wr_ack)						,
	.wr_data_count					(fifo_wr_data_count)				,
	.wr_rst_busy					(fifo_wr_rst_busy)					,
	.din							(fifo_din)							,
	.injectdbiterr					(fifo_injectdbiterr)				,
	.injectsbiterr					(fifo_injectsbiterr)				,
	.rd_clk							(fifo_rd_clk)						,
	.rd_en							(fifo_rd_en)						,
	.rst							(fifo_rst)							,
	.sleep							(fifo_sleep)						,
	.wr_clk							(fifo_wr_clk)						,
	.wr_en							(fifo_wr_en)
);
xpm_cdc_pulse #(
    .DEST_SYNC_FF					(2)									, 	// DECIMAL; range: 2-10
    .INIT_SYNC_FF					(1)									, 	// DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .REG_OUTPUT						(1)									, 	// DECIMAL; 0=disable registered output, 1=enable registered output
    .RST_USED						(0)									,	// DECIMAL; 0=no reset, 1=implement reset
    .SIM_ASSERT_CHK					(0)										// DECIMAL; 0=disable simulation messages, 1=enable simulation messages
)
xpm_cdc_pulse_inst (
    .dest_pulse						(m00_axi_wuser)						, 	// 1-bit output: Outputs a pulse the size of one dest_clk period 
    .dest_clk						(m00_axi_aclk)						,   // 1-bit input: Destination clock.
    .dest_rst						(m00_axi_aresetn)					,   // 1-bit input: optional; required when RST_USED = 1
    .src_clk						(cam_frame_dclk)					,   // 1-bit input: Source clock.
    .src_pulse						(cam_frame_vsync)					,   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
    .src_rst						(cam_data_asy_rst)       				// 1-bit input: optional; required when RST_USED = 1
);


/******************************************** User Logic ****************************************************************/
/*
// fifo logic
	DEPTH	=>	1024, 1024*24=24576, use a 36kRAM(36864)
	
	wwidth	=>	16	from frame
	rwidth	=>	32	ddr3 default

	wclk	=>	dclk@12Mhz
	rclk	=>	aclk@50Mhz

	wren	=>	href
	
	
// axi logic
	wid 	=>	00
	wuser 	=> 	vsync
	wvalid  =>  ~fifo_empty
	waddr	=>	Baseaddr 32'h00000000 and INCR, after vsync(single pic), clear
*/
assign	fifo_wr_en			=	cam_frame_href							;

assign	fifo_din			=	cam_frame_data							;

assign	fifo_wr_clk 		= 	cam_frame_dclk							;

assign	data_fifor_axiw 	= 	fifo_dout								;

assign	fifo_rd_clk			=	m00_axi_aclk							;

assign	fifo_rd_en			=	m00_axi_wvalid							;

assign	dvalid_fifor_axiw	=	fifo_data_valid 						;

assign	dempty_fifor_axiw	=	fifo_empty								;

assign	dfull_fifor_axiw	=	fifo_prog_full							;

assign	fifo_rst			=	cam_data_asy_rst						;

endmodule
