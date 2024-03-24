`timescale 1ns / 1ns

module cam_top
#(
    // Parameters of Axi Master Bus Interface M00_AXI
	parameter           C_M00_AXI_TARGET_SLAVE_BASE_ADDR    = 32'h00000000,
	parameter integer   C_M00_AXI_BURST_LEN	                = 16        ,
	parameter integer   C_M00_AXI_ID_WIDTH	                = 2         ,
	parameter integer   C_M00_AXI_ADDR_WIDTH	            = 32        ,
	parameter integer   C_M00_AXI_DATA_WIDTH	            = 32        ,
	parameter integer   C_M00_AXI_AWUSER_WIDTH	            = 1         ,
	parameter integer   C_M00_AXI_ARUSER_WIDTH	            = 0         ,
	parameter integer   C_M00_AXI_WUSER_WIDTH	            = 0         ,
	parameter integer   C_M00_AXI_RUSER_WIDTH	            = 0         ,
	parameter integer   C_M00_AXI_BUSER_WIDTH	            = 0         ,
    parameter integer   CAM_H_PIXEL                         = 768       ,   //CAM分辨率
    parameter integer   CAM_V_PIXEL                         = 1024         //CAM分辨率	
)
(
    input                                       cam_clk                 ,  // 时钟
    input                                       cam_asy_rst             ,  // 复位信号高电平有效
    // 摄像头接口                               
    input                                       cam_pclk                ,  // 数据像素时钟 来自ov5640
    input                                       cam_vsync               ,  // 场同步信号  来自ov5640
    input                                       cam_href                ,  // 行同步信号  来自ov5640
    input   [7:0]                               cam_data                ,  // 摄像头数据  来自ov5640  
    output                                      cam_rst_n               ,  // 复位信号    连接ov5640
    output                                      cam_pwdn                ,  // 电源休眠    连接ov5640
    output                                      cam_scl                 ,  // SCCB_SCL线 连接ov5640
    inout                                       cam_sda                 ,  // SCCB_SDA线 连接ov5640
    output                                      cam_init_done           ,  // 摄像头初始化完成
    // AXI 接口
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
/******************************************** Parameter Define ***********************************************************/
parameter   integer     SLAVE_ADDR      =   7'h3c                       ; // OV5640的器件地址7'h3c
parameter   integer     CLK_FREQ        =   27'd50_000_000              ; // cam模块的驱动时钟频率 
parameter   integer     I2C_FREQ        =   18'd250_000                 ; // i2c的SCL时钟频率,不超过400KHz

/******************************************** Wire Define ****************************************************************/
wire                                        i2c_dri_clk                 ;   // I2C操作时钟
wire                                        i2c_exec                    ;   // I2C触发执行信号
wire        [23:0]                          i2c_data                    ;   // I2C要配置的地址与数据(高16位地址,低8位数据)          
wire                                        i2c_done                    ;   // I2C寄存器配置完成信号

wire        [ 7:0]                          i2c_data_r                  ;   // I2C读出的数据
wire                                        i2c_rh_wl                   ;   // I2C读写控制信号

// 用户接口     
wire                                        cam_frame_vsync             ;   // 帧有效信号    
wire                                        cam_frame_href              ;   // 行有效信号
wire                                        cam_frame_valid             ;   // 数据有效使能信号
wire        [15:0]                          cam_frame_data              ;   // 有效数据  

wire        [12:0]                          cam_h_pixel                 ;   // 水平方向分辨率
wire        [12:0]                          cam_v_pixel                 ;   // 垂直方向分辨率
wire        [12:0]                          total_h_pixel               ;   // 水平总像素大小
wire        [12:0]                          total_v_pixel               ;   // 垂直总像素大小

/******************************************** Smart Reset ****************************************************************/
(*keep = "true"*)   reg     cam_rst_reg0                                ;
(*keep = "true"*)   reg     cam_rst_reg1                                ;
(*keep = "true"*)   wire    cam_rst                                     ;
(*keep = "true"*)   wire    i2c_dri_rst                                 ;
(*keep = "true"*)   wire    cam_cfg_asy_rst                             ;
(*keep = "true"*)   wire    cam_data_asy_rst                            ;

always @(posedge cam_clk or posedge cam_asy_rst) begin
    if(cam_asy_rst) begin
        cam_rst_reg0 <= 'd1;
        cam_rst_reg0 <= 'd1;
    end
    else begin
        cam_rst_reg0 <= 'd0;
        cam_rst_reg1 <= cam_rst_reg0;
    end
end

//cam golobal
assign      cam_rst = cam_rst_reg1                                      ;
//i2c_dri: same clk => same rst                             
assign      i2c_dri_rst  = cam_rst                                      ;
//cfg: diff clk => asy rst                              
assign      cam_cfg_asy_rst  = cam_rst                                  ;
//data: diff clk => asy rst                             
assign      cam_data_asy_rst = cam_rst                                  ;

/******************************************** Continuous Assignments *****************************************************/
// 电源休眠模式选择 0：正常模式 1：电源休眠模式
assign      cam_pwdn  = 1'b0                                            ;

assign      cam_rst_n = 1'b1                                            ;

assign      total_h_pixel   =   CAM_H_PIXEL + 1216                      ;
 
assign      total_v_pixel   =   CAM_V_PIXEL + 504                       ;

/******************************************** Instantiation **************************************************************/    
// CFG配置模块 时钟为250Khz的i2c_clk
ov5640_cfg u_ov5640_cfg
(
    .i2c_dri_clk                            (i2c_dri_clk)               ,
    .cam_cfg_asy_rst                        (cam_cfg_asy_rst)           ,

    .i2c_exec                               (i2c_exec)                  ,
    .i2c_data                               (i2c_data)                  ,
    .i2c_rh_wl                              (i2c_rh_wl)                 ,        
    .i2c_done                               (i2c_done)                  , 
    .i2c_data_r                             (i2c_data_r)                ,   

    .cam_h_pixel                            (cam_h_pixel)               ,      
    .cam_v_pixel                            (cam_v_pixel)               ,     
    .total_h_pixel                          (total_h_pixel)             ,    
    .total_v_pixel                          (total_v_pixel)             ,    

    .cam_init_done                          (cam_init_done)         
);   
    
// I2C驱动模块                          
i2c_dri #(                          
    .SLAVE_ADDR                             (SLAVE_ADDR)                ,       
    .CLK_FREQ                               (CLK_FREQ  )                ,              
    .I2C_FREQ                               (I2C_FREQ  ) 
)
u_i2c_dri
(
    .cam_clk                                (cam_clk)                   ,
    .i2c_dri_rst                            (i2c_dri_rst)               ,

    .i2c_exec                               (i2c_exec  )                ,    
    .i2c_rh_wl                              (i2c_rh_wl )                ,        
    .i2c_addr                               (i2c_data[23:8])            ,   
    .i2c_data_w                             (i2c_data[7:0])             ,   
    .i2c_data_r                             (i2c_data_r)                ,   
    .i2c_done                               (i2c_done  )                ,

    .i2c_scl                                (cam_scl   )                ,   
    .i2c_sda                                (cam_sda   )                ,   

    .i2c_dri_clk                            (i2c_dri_clk)       
);
   
// Cam图像数据采集模块 系统初始化完成之后再开始采集数据 
cam_data_frame u_cam_data_frame
(      
    .cam_data_asy_rst                       (cam_data_asy_rst)          ,
                        
    .cam_pclk                               (cam_pclk)                  ,
    .cam_vsync                              (cam_vsync)                 ,
    .cam_href                               (cam_href)                  ,
    .cam_data                               (cam_data)                  ,         

    .cam_frame_vsync                        (cam_frame_vsync)           ,
    .cam_frame_href                         (cam_frame_href )           ,
    .cam_frame_valid                        (cam_frame_valid)           ,   // 数据有效使能信号
    .cam_frame_data                         (cam_frame_data )           ,   // 有效数据
    .cam_frame_dclk                         (cam_frame_dclk ) 		        // 随路时钟 
);


// AXI master
myip_v1_0 #(
    .C_M00_AXI_TARGET_SLAVE_BASE_ADDR (C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
    .C_M00_AXI_BURST_LEN	          (C_M00_AXI_BURST_LEN	           ),
    .C_M00_AXI_ID_WIDTH	              (C_M00_AXI_ID_WIDTH	           ),
    .C_M00_AXI_ADDR_WIDTH	          (C_M00_AXI_ADDR_WIDTH	           ),
    .C_M00_AXI_DATA_WIDTH	          (C_M00_AXI_DATA_WIDTH	           ),
    .C_M00_AXI_AWUSER_WIDTH	          (C_M00_AXI_AWUSER_WIDTH	       ),
    .C_M00_AXI_ARUSER_WIDTH	          (C_M00_AXI_ARUSER_WIDTH	       ),
    .C_M00_AXI_WUSER_WIDTH	          (C_M00_AXI_WUSER_WIDTH	       ),
    .C_M00_AXI_RUSER_WIDTH	          (C_M00_AXI_RUSER_WIDTH	       ),
    .C_M00_AXI_BUSER_WIDTH	          (C_M00_AXI_BUSER_WIDTH	       )
)
u_myip_v1_0
(
    .cam_data_asy_rst                   (cam_data_asy_rst    )          ,
    .cam_frame_vsync                    (cam_frame_vsync     )          ,
    .cam_frame_href                     (cam_frame_href      )          ,
    .cam_frame_valid                    (cam_frame_valid     )          ,
    .cam_frame_data                     (cam_frame_data      )          ,
    .cam_frame_dclk                     (cam_frame_dclk      )          ,

    .m00_axi_init_axi_txn               (m00_axi_init_axi_txn)          ,
    .m00_axi_txn_done                   (m00_axi_txn_done    )          ,
    .m00_axi_error                      (m00_axi_error       )          ,
    .m00_axi_aclk                       (m00_axi_aclk        )          ,
    .m00_axi_aresetn                    (m00_axi_aresetn     )          ,
    .m00_axi_awid                       (m00_axi_awid        )          ,
    .m00_axi_awaddr                     (m00_axi_awaddr      )          ,
    .m00_axi_awlen                      (m00_axi_awlen       )          ,
    .m00_axi_awsize                     (m00_axi_awsize      )          ,
    .m00_axi_awburst                    (m00_axi_awburst     )          ,
    .m00_axi_awlock                     (m00_axi_awlock      )          ,
    .m00_axi_awcache                    (m00_axi_awcache     )          ,
    .m00_axi_awprot                     (m00_axi_awprot      )          ,
    .m00_axi_awqos                      (m00_axi_awqos       )          ,
    .m00_axi_awuser                     (m00_axi_awuser      )          ,
    .m00_axi_awvalid                    (m00_axi_awvalid     )          ,
    .m00_axi_awready                    (m00_axi_awready     )          ,
    .m00_axi_wdata                      (m00_axi_wdata       )          ,
    .m00_axi_wstrb                      (m00_axi_wstrb       )          ,
    .m00_axi_wlast                      (m00_axi_wlast       )          ,
    .m00_axi_wuser                      (m00_axi_wuser       )          ,
    .m00_axi_wvalid                     (m00_axi_wvalid      )          ,
    .m00_axi_wready                     (m00_axi_wready      )          ,
    .m00_axi_bid                        (m00_axi_bid         )          ,
    .m00_axi_bresp                      (m00_axi_bresp       )          ,
    .m00_axi_buser                      (m00_axi_buser       )          ,
    .m00_axi_bvalid                     (m00_axi_bvalid      )          ,
    .m00_axi_bready                     (m00_axi_bready      )          ,
    .m00_axi_arid                       (m00_axi_arid        )          ,
    .m00_axi_araddr                     (m00_axi_araddr      )          ,
    .m00_axi_arlen                      (m00_axi_arlen       )          ,
    .m00_axi_arsize                     (m00_axi_arsize      )          ,
    .m00_axi_arburst                    (m00_axi_arburst     )          ,
    .m00_axi_arlock                     (m00_axi_arlock      )          ,
    .m00_axi_arcache                    (m00_axi_arcache     )          ,
    .m00_axi_arprot                     (m00_axi_arprot      )          ,
    .m00_axi_arqos                      (m00_axi_arqos       )          ,
    .m00_axi_aruser                     (m00_axi_aruser      )          ,
    .m00_axi_arvalid                    (m00_axi_arvalid     )          ,
    .m00_axi_arready                    (m00_axi_arready     )          ,
    .m00_axi_rid                        (m00_axi_rid         )          ,
    .m00_axi_rdata                      (m00_axi_rdata       )          ,
    .m00_axi_rresp                      (m00_axi_rresp       )          ,
    .m00_axi_rlast                      (m00_axi_rlast       )          ,
    .m00_axi_ruser                      (m00_axi_ruser       )          ,
    .m00_axi_rvalid                     (m00_axi_rvalid      )          ,
    .m00_axi_rready                     (m00_axi_rready      )            
);

endmodule
