/******************************************************************************** (c) Copyright 2023 Yu Zhang. All rights reserved. *************************************************************************/
/********************************************************************************************** CODES START HERE ********************************************************************************************/

`timescale 1 ns / 1 ns
module myip_v1_0_M00_AXI #
(
// Base address of targeted slave
	parameter  				C_M_TARGET_SLAVE_BASE_ADDR	= 32'h00000000	,
// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
	parameter 	integer 	C_M_AXI_BURST_LEN			= 128			,
// Thread ID Width
	parameter 	integer	 	C_M_AXI_ID_WIDTH			= 1				,
// Width of Address Bus
	parameter 	integer 	C_M_AXI_ADDR_WIDTH			= 32			,
// Width of Data Bus
	parameter 	integer 	C_M_AXI_DATA_WIDTH			= 32			,
// Width of User Write Address Bus
	parameter 	integer 	C_M_AXI_AWUSER_WIDTH		= 0				,
// Width of User Read Address Bus
	parameter 	integer 	C_M_AXI_ARUSER_WIDTH		= 0				,
// Width of User Write Data Bus
	parameter 	integer 	C_M_AXI_WUSER_WIDTH			= 0				,		
// Width of User Read Data Bus
	parameter 	integer 	C_M_AXI_RUSER_WIDTH			= 0				,
// Width of User Response Bus
	parameter 	integer 	C_M_AXI_BUSER_WIDTH			= 0
)
(
/*******************Global Signals****************************************/		

// Asserts when ERROR is detected
	output 	reg  									ERROR				,
// Global Clock Signal.
	input 	wire  									M_AXI_ACLK			,
// Global Reset Singal. This Signal is Active Low
	input 	wire  									M_AXI_ARESETN		,

/*******************Master Interface Write Address **********************/
	
	output 	wire 	[C_M_AXI_ID_WIDTH-1 : 0] 		M_AXI_AWID			,
// Master Interface Write Address
	output 	wire 	[C_M_AXI_ADDR_WIDTH-1 : 0] 		M_AXI_AWADDR		,
// Burst length. The burst length gives the exact number of transfers in a burst
	output 	wire 	[7 : 0] 						M_AXI_AWLEN			,
// Burst size. This signal indicates the size of each transfer in the burst
	output 	wire 	[2 : 0] 						M_AXI_AWSIZE		,
// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
	output 	wire 	[1 : 0] 						M_AXI_AWBURST		,
// Lock type. Provides additional information about the atomic characteristics of the transfer.
	output 	wire  									M_AXI_AWLOCK		,
// Memory type. This signal indicates how transactions are required to progress through a system.
	output 	wire 	[3 : 0]			 				M_AXI_AWCACHE,		
// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
	output 	wire 	[2 : 0] 						M_AXI_AWPROT		,
// Quality of Service, QoS identifier sent for each write transaction.
	output 	wire 	[3 : 0] 						M_AXI_AWQOS			,
// Optional User-defined signal in the write address channel.
	output 	wire 	[C_M_AXI_AWUSER_WIDTH-1 : 0] 	M_AXI_AWUSER		,
// Write address valid. This signal indicates that the channel is signaling valid write address and control information.
	output 	wire 									M_AXI_AWVALID		,
// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals
	input 	wire  									M_AXI_AWREADY		,

/*******************Master Interface Write Data***************************/

	output 	wire 	[C_M_AXI_DATA_WIDTH-1 : 0] 		M_AXI_WDATA			,
// Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
	output 	wire 	[C_M_AXI_DATA_WIDTH/8-1 : 0] 	M_AXI_WSTRB			,
// Write last. This signal indicates the last transfer in a write burst.
	output 	wire 	 								M_AXI_WLAST			,
// Optional User-defined signal in the write data channel.
	output 	wire 	[C_M_AXI_WUSER_WIDTH-1 : 0] 	M_AXI_WUSER			,
// Write valid. This signal indicates that valid write data and strobes are available
	output 	wire 						 			M_AXI_WVALID		,
// Write ready. This signal indicates that the slave can accept the write data.
	input 	wire 					 				M_AXI_WREADY		,

/*******************Master Interface Write Respons***********************/
	input 	wire 	[C_M_AXI_ID_WIDTH-1 : 0] 		M_AXI_BID			,
// Write response. This signal indicates the status of the write transaction.
	input 	wire 	[1 : 0] 						M_AXI_BRESP			,
// Optional User-defined signal in the write response channel
	input 	wire 	[C_M_AXI_BUSER_WIDTH-1 : 0] 	M_AXI_BUSER			,
// Write response valid. This signal indicates that the channel is signaling a valid write response.
	input 	wire 	 								M_AXI_BVALID		,
// Response ready. This signal indicates that the master can accept a write response.
	output 	wire 									M_AXI_BREADY		,

/******************Master Interface Read Address*************************/
	output 	wire 	[C_M_AXI_ID_WIDTH-1 : 0] 		M_AXI_ARID			,
// Read address. This signal indicates the initial address of a read burst transaction.
	output 	wire 	[C_M_AXI_ADDR_WIDTH-1 : 0]		M_AXI_ARADDR		,
// Burst length. The burst length gives the exact number of transfers in a burst
	output 	wire 	[7 : 0] 						M_AXI_ARLEN			,
// Burst size. This signal indicates the size of each transfer in the burst
	output 	wire 	[2 : 0] 						M_AXI_ARSIZE		,
// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
	output 	wire 	[1 : 0] 						M_AXI_ARBURST		,
// Lock type. Provides additional information about the atomic characteristics of the transfer.
	output 	wire 	 								M_AXI_ARLOCK		,
// Memory type. This signal indicates how transactions are required to progress through a system.
	output 	wire 	[3 : 0] 						M_AXI_ARCACHE		,
// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
	output 	wire 	[2 : 0] 						M_AXI_ARPROT		,
// Quality of Service, QoS identifier sent for each read transaction
	output 	wire 	[3 : 0] 						M_AXI_ARQOS			,
// Optional User-defined signal in the read address channel.
	output 	wire 	[C_M_AXI_ARUSER_WIDTH-1 : 0] 	M_AXI_ARUSER		,
// Write address valid. This signal indicates that the channel is signaling valid read address and control information
	output 	wire 	 								M_AXI_ARVALID		,
// Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals
	input 	wire 	 								M_AXI_ARREADY,		

/******************Master Interface Read******************************/
// Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
	input 	wire 	[C_M_AXI_ID_WIDTH-1 : 0] 		M_AXI_RID			,
// Master Read Data	
	input 	wire 	[C_M_AXI_DATA_WIDTH-1 : 0] 		M_AXI_RDATA			,
// Read response. This signal indicates the status of the read transfer
	input 	wire 	[1 : 0] 						M_AXI_RRESP			,
// Read last. This signal indicates the last transfer in a read burst
	input 	wire 	 								M_AXI_RLAST			,
// Optional User-defined signal in the read address channel.
	input 	wire 	[C_M_AXI_RUSER_WIDTH-1 : 0] 	M_AXI_RUSER			,
// Read valid. This signal indicates that the channel is signaling the required read data.
	input 	wire 	 								M_AXI_RVALID		,
// Read ready. This signal indicates that the master can accept the read data and response information.
	output 	wire 	 								M_AXI_RREADY		,

// user interface
	input	wire	[C_M_AXI_DATA_WIDTH-1 : 0] 		data_fifor_axiw		,
	input	wire									dvalid_fifor_axiw	,
	input	wire									dfull_fifor_axiw	,
	input	wire									dempty_fifor_axiw	
	);

/**************************************************** Function Define ***********************************************************************************************************/
function integer clogb2 (input integer bit_depth);     
begin     
  	for(clogb2 = 0; bit_depth > 0; clogb2 = clogb2+1) 
    	bit_depth = bit_depth >> 1; 
end     
endfunction       

/**************************************************** Parameter Define **********************************************************************************************************/

localparam integer  C_TRANSACTIONS_INDEX	= clogb2(C_M_AXI_BURST_LEN-1); // number of transaction.
	
localparam integer  C_MASTER_LENGTH			= 12;

localparam integer  C_NO_BURSTS_REQ 		= C_MASTER_LENGTH-clogb2((C_M_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH/8)-1); // total number of burst transfers is master length divided by burst length and burst size

localparam integer	SINGLE_TRAN_TOTLE 		= 1024/C_M_AXI_BURST_LEN; // number of burst to send a row of OV5640 @1024*798

/**************************************************** Local Signal Define *******************************************************************************************************/
// AXI4 internal temp signals
reg  	[C_M_AXI_ADDR_WIDTH-1 : 0] 		axi_awaddr						;	
reg  									axi_awvalid						;
reg  									axi_wlast						;	
reg 	 								axi_wvalid						;	
reg  									axi_bready						;	
reg  	[C_M_AXI_ADDR_WIDTH-1 : 0] 		axi_araddr						;	
reg  									axi_arvalid						;
reg  									axi_rready						;	

//write beat count in a burst	
reg  	[C_TRANSACTIONS_INDEX : 0] 		write_index						;
//read beat count in a burst	
reg 	[C_TRANSACTIONS_INDEX : 0] 		read_index						;

//size of C_M_AXI_BURST_LEN length burst in bytes	
wire 	[C_TRANSACTIONS_INDEX+2 : 0] 	burst_size_bytes				;

//Interface response error flags	
wire  									write_resp_error				;
wire  									read_resp_error					;

// User Interface	
wire									single_tran_start				;
reg										single_tran_start_r0			;
reg										single_tran_start_r1			;
reg										axi_waitfifo					;
reg										single_tran_done				;
reg		[3:0]							single_tran_cnt					;



/**************************************************** Smart Reset *************************************************************************************************************/
(*keep = "true"*)	reg 	m_axi_reset_reg0							;
(*keep = "true"*)	reg 	m_axi_reset_reg1							;
(*keep = "true"*)	wire 	m_axi_reset									;

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if (!M_AXI_ARESETN)     
    	begin     
        m_axi_reset_reg0 <= 'd1;     
        m_axi_reset_reg1 <= 'd1;     
    	end  
    else        
    	begin  
        m_axi_reset_reg0 <= 'd0;
        m_axi_reset_reg1 <= m_axi_reset_reg0;  
    	end       
end
//local rst 
assign	m_axi_reset 	= m_axi_reset_reg1								;


/******************************************** Continuous Assignments **********************************************************************************************************/
//I/O Connections. Write Address (AW)	
assign  M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr		;	// The AXI address is target base address + active offset range

assign  M_AXI_AWLEN		= C_M_AXI_BURST_LEN - 1							;	// Burst Length is number of transaction beats

assign  M_AXI_AWSIZE	= clogb2((C_M_AXI_DATA_WIDTH/8)-1)				;	// Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used

assign  M_AXI_AWBURST	= 2'b01											;	// INCR burst type is usually used

assign  M_AXI_AWVALID	= axi_awvalid									;	// Show Addwr Valid

//I/O C onnections. Write (W)			
assign  M_AXI_WDATA		= axi_wvalid ? data_fifor_axiw	: 'd0			;	// Write Data(W), from asyfifo read port

assign  M_AXI_WSTRB		= {(C_M_AXI_DATA_WIDTH/8){1'b1}}				;	// All bursts are complete and aligned in this example

assign  M_AXI_WLAST		= axi_wlast										;	 // last indicate

assign  M_AXI_WVALID	= axi_wvalid									;	// Show Wrdata Valid

//I/O C onnections. Write Response (B)			
assign  M_AXI_BREADY	= axi_bready									;	// Show response ready

//I/O C onnections. Read Address (AR)			
assign  M_AXI_ARID		= 'd0											;	// ARID

assign  M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_araddr		;	// ARADDR

assign  M_AXI_ARLEN		= C_M_AXI_BURST_LEN - 1							;	// Burst Length is number of transaction beats minus 1

assign  M_AXI_ARSIZE	= clogb2((C_M_AXI_DATA_WIDTH/8)-1)				;	// Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used

assign  M_AXI_ARBURST	= 2'b01											;	// INCR burst type is usually used, except for keyhole bursts

assign  M_AXI_ARVALID	= axi_arvalid									;	// Show Ardata Valid

//I/O Connections. Read and Read Response (R)		
assign 	M_AXI_RREADY	= axi_rready									;	// Show read ready of master

// signals determine transaction attributes and cache properties	
assign 	M_AXI_ARLOCK	= 'd0											;
assign 	M_AXI_AWLOCK	= 'd0											;
assign 	M_AXI_AWCACHE	= 4'b0010										;	
assign 	M_AXI_AWPROT	= 3'h0											;
assign 	M_AXI_AWQOS		= 4'h0											;
assign 	M_AXI_ARCACHE	= 4'b0010										;
assign 	M_AXI_ARPROT	= 3'h0											;
assign 	M_AXI_ARQOS		= 4'h0											;
assign 	M_AXI_ARUSER	= 'd1											;

//Burst size in bytes
assign 	burst_size_bytes= C_M_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH / 8		;


/******************************************** Write Address Channel **********************************************************************************************************/

always @(posedge M_AXI_ACLK) // The Manager must not wait for the Subordinate to assert AWREADY or WREADY before asserting AWVALID or WVALID.   
begin 
	if (m_axi_reset)  
	    axi_awvalid <= 'd0;    
	else if (~axi_awvalid && single_tran_start) // If previously not valid, start new transaction       
	    axi_awvalid <= 'd1;       
	else if (M_AXI_AWREADY && axi_awvalid) // AWVALID must remain asserted until the rising clock edge after the Subordinate asserts AWREADY  
	    axi_awvalid <= 'd0;     
	else
	    axi_awvalid <= axi_awvalid;      
end
   
// Next address after AWREADY indicates previous address acceptance    
always @(posedge M_AXI_ACLK)
begin 
	if (m_axi_reset)   
	    axi_awaddr <= 'd0;      
	else if (M_AXI_AWREADY && axi_awvalid)     
		axi_awaddr <= axi_awaddr + burst_size_bytes;
	else if (single_tran_done)
		axi_awaddr <= 'd0;
	else
		axi_awaddr <= axi_awaddr;        
end 


/******************************************** Write Data Channel *************************************************************************************************************/

always @(posedge M_AXI_ACLK) // get start beat
begin
	if (m_axi_reset)
		begin
		single_tran_start_r0 <= 'd0;
		single_tran_start_r1 <= 'd0;
		end
	else if ((!axi_waitfifo) && (write_index==0) && (single_tran_cnt < SINGLE_TRAN_TOTLE - 1))
		begin
		single_tran_start_r0 <= 'd1;
		single_tran_start_r1 <= single_tran_start_r0;	
		end
	else 
		begin
		single_tran_start_r0 <= 'd0;
		single_tran_start_r1 <= single_tran_start_r0;
		end 	
end

assign	single_tran_start = (!single_tran_start_r1) && (single_tran_start_r0);


always @(posedge M_AXI_ACLK)
begin
	if (m_axi_reset)		
		axi_waitfifo <= 'd1;
	else if (dfull_fifor_axiw)
		axi_waitfifo <= 'd0;
	else if (single_tran_done)
		axi_waitfifo <= 'd1;
	else
		axi_waitfifo <= axi_waitfifo;
end

always @(posedge M_AXI_ACLK)
begin
	if (m_axi_reset)
		begin
		single_tran_cnt  <= 'd0;
		single_tran_done <= 'd0;
		end
	else if (axi_wlast)
		begin
		single_tran_cnt  <= single_tran_cnt + 'd1;
		single_tran_done <= single_tran_done;
		end
	else if (single_tran_cnt == SINGLE_TRAN_TOTLE - 1)
		begin
		single_tran_cnt	 <= 'd0;
		single_tran_done <= 'd1;
		end
	else 
		begin
		single_tran_cnt  <= single_tran_cnt;
		single_tran_done <= 'd0;
		end
end

always @(posedge M_AXI_ACLK) // The Manager must not wait for the Subordinate to assert AWREADY or WREADY before asserting AWVALID or WVALID.   
begin 
	if (m_axi_reset)  
	    axi_wvalid <= 'd0;    
	else if (!axi_awvalid && single_tran_start) // If previously not valid, start new transaction       
	    axi_wvalid <= 'd1;       
	else if (axi_wlast) // AVALID must remain asserted until the last transfer was done       
	    axi_wvalid <= 'd0;     
	else
	    axi_wvalid <= axi_wvalid;      
end        

always @(posedge M_AXI_ACLK) // axi_wlast is asserted synchronize with the last write data when write_index indicates the last transfer  
begin
	if (m_axi_reset)  
		axi_wlast <= 'd0;
	else if (((write_index == C_M_AXI_BURST_LEN-1 && C_M_AXI_BURST_LEN >= 2) && axi_wvalid) || (C_M_AXI_BURST_LEN == 1))        
	    axi_wlast <= 'd1;    
	else    
	    axi_wlast <= 'd0;
end       
/* Burst length counter. Uses extra counter register bit to indicate terminal count to reduce decode logic */      
always @(posedge M_AXI_ACLK)
begin
	if (m_axi_reset)
	    write_index <= 'd0;    
	else if ((axi_wvalid && M_AXI_WREADY) || (write_index >= 1 && write_index < C_M_AXI_BURST_LEN - 1))  
	    write_index <= write_index + 'd1;  
	else if (write_index >= C_M_AXI_BURST_LEN - 1)
	    write_index <= 'd0; 
	else    
	    write_index <= write_index;     
end      


/******************************************** Write Response Channel *************************************************************************************************************/

always @(posedge M_AXI_ACLK)     
begin   
  	if (m_axi_reset)      
      	axi_bready <= 'd0;        
 	else if (M_AXI_BVALID && ~axi_bready) // accept/acknowledge bresp with axi_bready by the master when M_AXI_BVALID is asserted by slave   
      	axi_bready <= 'd1; 
  	else if (axi_bready)  // deassert after one clock cycle
      	axi_bready <= 'd0;
  	else  
    axi_bready <= axi_bready;      
end     
	        
// Flag any write response errors        
assign write_resp_error = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]; 
// for BRESP[1:0]
// 0b00 OKAY
// 0b01 EXOKAY
// 0b10 SLVERR
// 0b11 DECERR


/******************************************** Read Address Channel **************************************************************************************************************/
always @(posedge M_AXI_ACLK) 
begin  
	if (m_axi_reset)  
		axi_arvalid <= 'd0;     
	else if (~axi_arvalid)       
	    axi_arvalid <= 'd1;
	else if (M_AXI_ARREADY && axi_arvalid)      
	    axi_arvalid <= 'd0;    
	else       
	    axi_arvalid <= axi_arvalid;    
end       

always @(posedge M_AXI_ACLK)  // Next address after ARREADY indicates previous address acceptance       
begin        
  	if (m_axi_reset) 
    	axi_araddr <= 'b0;  
  	else if (M_AXI_ARREADY && axi_arvalid)       
      	axi_araddr <= axi_araddr + burst_size_bytes;
	else if (dempty_fifor_axiw)
		axi_araddr <= 'b0;
  	else       
    	axi_araddr <= axi_araddr;      
end 

/******************************************** Read Readrespose Channel **********************************************************************************************************/

always @(posedge M_AXI_ACLK) // Burst length counter. Uses extra counter register bit to indicate terminal count to reduce decode logic
begin  
	if (m_axi_reset)     
		read_index <= 'd0;  
	else if ((M_AXI_RVALID && axi_rready) || (read_index > 1) && (read_index <= C_M_AXI_BURST_LEN - 1))
		read_index <= read_index + 1;
	else if ((read_resp_error) || (read_index >= C_M_AXI_BURST_LEN))
		read_index <= 'd0;
	else 
		read_index <= read_index;
end  

always @(posedge M_AXI_ACLK) 
begin  
	if (m_axi_reset)     
	    axi_rready <= 'd0;    
	else if (M_AXI_RVALID)
		axi_rready <= ~(M_AXI_RLAST && axi_rready);      
    else
	    axi_rready <= axi_rready;
end

//Flag any read response errors
assign read_resp_error = axi_rready & M_AXI_RVALID & M_AXI_RRESP[1];


endmodule

/************************************************************************************* CODES END HERE **********************************************************************************************************/
/************************************************************************************* CONTACT ME WITH :********************************************************************************************************/
/************************************************************************************* 2656353013@QQ.COM *******************************************************************************************************/

