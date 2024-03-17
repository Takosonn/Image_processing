`timescale 1ns / 1ns

module ov5640_cfg
(  
    input                i2c_dri_clk    ,   // 时钟信号
    input                cam_cfg_asy_rst,   // asy复位信号，高电平有效
    // 分辨率接口
    input        [12:0]  cam_h_pixel    ,
    input        [12:0]  cam_v_pixel    ,
    input        [12:0]  total_h_pixel  ,   // 水平总像素大小
    input        [12:0]  total_v_pixel  ,   // 垂直总像素大小
    // i2c接口
    input        [7:0]   i2c_data_r     ,   // I2C读出的数据
    input                i2c_done       ,   // I2C寄存器配置完成信号
    output  reg          i2c_exec       ,   // I2C触发执行信号   
    output  reg  [23:0]  i2c_data       ,   // I2C要配置的地址与数据(高16位地址,低8位数据)
    output  reg          i2c_rh_wl      ,   // I2C读写控制信号
    output  reg          cam_init_done      // 初始化完成信号
);

/******************************************** Parameter Define ***********************************************************/
localparam  REG_NUM = 8'd250    ;   // 总共需要配置的寄存器个数

/******************************************** Reg Define *****************************************************************/
reg   [12:0]   por_wait_cnt     ;   // 等待延时计数器
reg   [7:0]    cfg_reg_cnt      ;   // 寄存器配置个数计数器

/******************************************** Smart Reset ****************************************************************/
(*keep = "true"*)   reg     cam_cfg_rst_reg0    ;
(*keep = "true"*)   reg     cam_cfg_rst_reg1    ;
(*keep = "true"*)   wire    cam_cfg_rst         ;

always @(posedge i2c_dri_clk or posedge cam_cfg_asy_rst) begin
    if(cam_cfg_asy_rst) begin
        cam_cfg_rst_reg0 <= 'd1;
        cam_cfg_rst_reg1 <= 'd1;
    end
    else begin
        cam_cfg_rst_reg0 <= 'd0;
        cam_cfg_rst_reg1 <= cam_cfg_rst_reg0;
    end
end

//local rst
assign  cam_cfg_rst = cam_cfg_rst_reg1;

/******************************************** Procedural Assignments *****************************************************/
// scl时钟配置成250khz,周期为4us 5000*4us = 20ms
// OV5640上电到开始配置IIC至少等待20ms
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        por_wait_cnt <= 'd0;
    else if(por_wait_cnt < 'd5000) 
        por_wait_cnt <= por_wait_cnt + 1;
    else
        por_wait_cnt <= por_wait_cnt;
end

// 寄存器配置个数计数    
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        cfg_reg_cnt <= 'd0;
    else if(i2c_exec)   
        cfg_reg_cnt <= cfg_reg_cnt + 1;
    else
        cfg_reg_cnt <= cfg_reg_cnt;
end

// i2c触发执行信号   
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        i2c_exec <= 'd0;
    else if((por_wait_cnt == 'd4999) || (i2c_done && (cfg_reg_cnt < REG_NUM)))
        i2c_exec <= 'd1;
    else
        i2c_exec <= 'd0;
end 

// 配置I2C读写控制信号
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        i2c_rh_wl <= 'd1;
    else if(cfg_reg_cnt == 'd2)  
        i2c_rh_wl <= 'd0;
    else 
        i2c_rh_wl <= i2c_rh_wl;
end

// 初始化完成信号
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        cam_init_done <= 'd0;
    else if((cfg_reg_cnt == REG_NUM) && i2c_done)  
        cam_init_done <= 'd1;  
    else
        cam_init_done <= cam_init_done;
end

// 配置寄存器地址与数据
always @(posedge i2c_dri_clk) begin
    if(cam_cfg_rst)
        i2c_data <= 'd0;
    else begin
        case(cfg_reg_cnt)
            // 先对寄存器进行软件复位，使寄存器恢复初始值
            // 寄存器软件复位后，需要延时1ms才能配置其它寄存器
            'd0  : i2c_data <= {16'h300a,8'h0};  
            'd1  : i2c_data <= {16'h300b,8'h0};  
            'd2  : i2c_data <= {16'h3008,8'h82}; // Bit[7]:复位 Bit[6]:电源休眠
            'd3  : i2c_data <= {16'h3008,8'h02}; // 正常工作模式
            'd4  : i2c_data <= {16'h3103,8'h02}; // Bit[1]:1 PLL Clock
            // 引脚输入/输出控制 FREX/VSYNC/HREF/PCLK/D[9:6]
            'd5  : i2c_data <= {8'h30,8'h17,8'hff};
            // 引脚输入/输出控制 D[5:0]/GPIO1/GPIO0 
            'd6  : i2c_data <= {16'h3018,8'hff};
            'd7  : i2c_data <= {16'h3037,8'h13}; // PLL分频控制
            'd8  : i2c_data <= {16'h3108,8'h01}; // 系统根分频器
            'd9  : i2c_data <= {16'h3630,8'h36};
            'd10 : i2c_data <= {16'h3631,8'h0e};
            'd11 : i2c_data <= {16'h3632,8'he2};
            'd12 : i2c_data <= {16'h3633,8'h12};
            'd13 : i2c_data <= {16'h3621,8'he0};
            'd14 : i2c_data <= {16'h3704,8'ha0};
            'd15 : i2c_data <= {16'h3703,8'h5a};
            'd16 : i2c_data <= {16'h3715,8'h78};
            'd17 : i2c_data <= {16'h3717,8'h01};
            'd18 : i2c_data <= {16'h370b,8'h60};
            'd19 : i2c_data <= {16'h3705,8'h1a};
            'd20 : i2c_data <= {16'h3905,8'h02};
            'd21 : i2c_data <= {16'h3906,8'h10};
            'd22 : i2c_data <= {16'h3901,8'h0a};
            'd23 : i2c_data <= {16'h3731,8'h12};
            'd24 : i2c_data <= {16'h3600,8'h08}; // VCM控制,用于自动聚焦
            'd25 : i2c_data <= {16'h3601,8'h33}; // VCM控制,用于自动聚焦
            'd26 : i2c_data <= {16'h302d,8'h60}; // 系统控制
            'd27 : i2c_data <= {16'h3620,8'h52};
            'd28 : i2c_data <= {16'h371b,8'h20};
            'd29 : i2c_data <= {16'h471c,8'h50};
            'd30 : i2c_data <= {16'h3a13,8'h43}; // AEC(自动曝光控制)
            'd31 : i2c_data <= {16'h3a18,8'h00}; // AEC 增益上限
            'd32 : i2c_data <= {16'h3a19,8'hf8}; // AEC 增益上限
            'd33 : i2c_data <= {16'h3635,8'h13};
            'd34 : i2c_data <= {16'h3636,8'h03};
            'd35 : i2c_data <= {16'h3634,8'h40};
            'd36 : i2c_data <= {16'h3622,8'h01};
            'd37 : i2c_data <= {16'h3c01,8'h34};
            'd38 : i2c_data <= {16'h3c04,8'h28};
            'd39 : i2c_data <= {16'h3c05,8'h98};
            'd40 : i2c_data <= {16'h3c06,8'h00}; // light meter 1 阈值[15:8]
            'd41 : i2c_data <= {16'h3c07,8'h08}; // light meter 1 阈值[7:0]
            'd42 : i2c_data <= {16'h3c08,8'h00}; // light meter 2 阈值[15:8]
            'd43 : i2c_data <= {16'h3c09,8'h1c}; // light meter 2 阈值[7:0]
            'd44 : i2c_data <= {16'h3c0a,8'h9c}; // sample number[15:8]
            'd45 : i2c_data <= {16'h3c0b,8'h40}; // sample number[7:0]
            'd46 : i2c_data <= {16'h3810,8'h00}; // Timing Hoffset[11:8]
            'd47 : i2c_data <= {16'h3811,8'h10}; // Timing Hoffset[7:0]
            'd48 : i2c_data <= {16'h3812,8'h00}; // Timing Voffset[10:8]
            'd49 : i2c_data <= {16'h3708,8'h64};
            'd50 : i2c_data <= {16'h4001,8'h02}; // BLC(黑电平校准)补偿起始行号
            'd51 : i2c_data <= {16'h4005,8'h1a}; // BLC(黑电平校准)补偿始终更新
            'd52 : i2c_data <= {16'h3000,8'h00}; // 系统块复位控制
            'd53 : i2c_data <= {16'h3004,8'hff}; // 时钟使能控制
            'd54 : i2c_data <= {16'h4300,8'h61}; // 格式控制 RGB565
            'd55 : i2c_data <= {16'h501f,8'h01}; // ISP RGB
            'd56 : i2c_data <= {16'h440e,8'h00};
            'd57 : i2c_data <= {16'h5000,8'ha7}; // ISP控制
            'd58 : i2c_data <= {16'h3a0f,8'h30}; // AEC控制;stable range in high
            'd59 : i2c_data <= {16'h3a10,8'h28}; // AEC控制;stable range in low
            'd60 : i2c_data <= {16'h3a1b,8'h30}; // AEC控制;stable range out high
            'd61 : i2c_data <= {16'h3a1e,8'h26}; // AEC控制;stable range out low
            'd62 : i2c_data <= {16'h3a11,8'h60}; // AEC控制; fast zone high
            'd63 : i2c_data <= {16'h3a1f,8'h14}; // AEC控制; fast zone low
            // LENC(镜头校正)控制 16'h5800~16'h583d
            'd64 : i2c_data <= {16'h5800,8'h23}; 
            'd65 : i2c_data <= {16'h5801,8'h14};
            'd66 : i2c_data <= {16'h5802,8'h0f};
            'd67 : i2c_data <= {16'h5803,8'h0f};
            'd68 : i2c_data <= {16'h5804,8'h12};
            'd69 : i2c_data <= {16'h5805,8'h26};
            'd70 : i2c_data <= {16'h5806,8'h0c};
            'd71 : i2c_data <= {16'h5807,8'h08};
            'd72 : i2c_data <= {16'h5808,8'h05};
            'd73 : i2c_data <= {16'h5809,8'h05};
            'd74 : i2c_data <= {16'h580a,8'h08};
            'd75 : i2c_data <= {16'h580b,8'h0d};
            'd76 : i2c_data <= {16'h580c,8'h08};
            'd77 : i2c_data <= {16'h580d,8'h03};
            'd78 : i2c_data <= {16'h580e,8'h00};
            'd79 : i2c_data <= {16'h580f,8'h00};
            'd80 : i2c_data <= {16'h5810,8'h03};
            'd81 : i2c_data <= {16'h5811,8'h09};
            'd82 : i2c_data <= {16'h5812,8'h07};
            'd83 : i2c_data <= {16'h5813,8'h03};
            'd84 : i2c_data <= {16'h5814,8'h00};
            'd85 : i2c_data <= {16'h5815,8'h01};
            'd86 : i2c_data <= {16'h5816,8'h03};
            'd87 : i2c_data <= {16'h5817,8'h08};
            'd88 : i2c_data <= {16'h5818,8'h0d};
            'd89 : i2c_data <= {16'h5819,8'h08};
            'd90 : i2c_data <= {16'h581a,8'h05};
            'd91 : i2c_data <= {16'h581b,8'h06};
            'd92 : i2c_data <= {16'h581c,8'h08};
            'd93 : i2c_data <= {16'h581d,8'h0e};
            'd94 : i2c_data <= {16'h581e,8'h29};
            'd95 : i2c_data <= {16'h581f,8'h17};
            'd96 : i2c_data <= {16'h5820,8'h11};
            'd97 : i2c_data <= {16'h5821,8'h11};
            'd98 : i2c_data <= {16'h5822,8'h15};
            'd99 : i2c_data <= {16'h5823,8'h28};
            'd100: i2c_data <= {16'h5824,8'h46};
            'd101: i2c_data <= {16'h5825,8'h26};
            'd102: i2c_data <= {16'h5826,8'h08};
            'd103: i2c_data <= {16'h5827,8'h26};
            'd104: i2c_data <= {16'h5828,8'h64};
            'd105: i2c_data <= {16'h5829,8'h26};
            'd106: i2c_data <= {16'h582a,8'h24};
            'd107: i2c_data <= {16'h582b,8'h22};
            'd108: i2c_data <= {16'h582c,8'h24};
            'd109: i2c_data <= {16'h582d,8'h24};
            'd110: i2c_data <= {16'h582e,8'h06};
            'd111: i2c_data <= {16'h582f,8'h22};
            'd112: i2c_data <= {16'h5830,8'h40};
            'd113: i2c_data <= {16'h5831,8'h42};
            'd114: i2c_data <= {16'h5832,8'h24};
            'd115: i2c_data <= {16'h5833,8'h26};
            'd116: i2c_data <= {16'h5834,8'h24};
            'd117: i2c_data <= {16'h5835,8'h22};
            'd118: i2c_data <= {16'h5836,8'h22};
            'd119: i2c_data <= {16'h5837,8'h26};
            'd120: i2c_data <= {16'h5838,8'h44};
            'd121: i2c_data <= {16'h5839,8'h24};
            'd122: i2c_data <= {16'h583a,8'h26};
            'd123: i2c_data <= {16'h583b,8'h28};
            'd124: i2c_data <= {16'h583c,8'h42};
            'd125: i2c_data <= {16'h583d,8'hce};
            // AWB(自动白平衡控制) 16'h5180~16'h519e
            'd126: i2c_data <= {16'h5180,8'hff};
            'd127: i2c_data <= {16'h5181,8'hf2};
            'd128: i2c_data <= {16'h5182,8'h00};
            'd129: i2c_data <= {16'h5183,8'h14};
            'd130: i2c_data <= {16'h5184,8'h25};
            'd131: i2c_data <= {16'h5185,8'h24};
            'd132: i2c_data <= {16'h5186,8'h09};
            'd133: i2c_data <= {16'h5187,8'h09};
            'd134: i2c_data <= {16'h5188,8'h09};
            'd135: i2c_data <= {16'h5189,8'h75};
            'd136: i2c_data <= {16'h518a,8'h54};
            'd137: i2c_data <= {16'h518b,8'he0};
            'd138: i2c_data <= {16'h518c,8'hb2};
            'd139: i2c_data <= {16'h518d,8'h42};
            'd140: i2c_data <= {16'h518e,8'h3d};
            'd141: i2c_data <= {16'h518f,8'h56};
            'd142: i2c_data <= {16'h5190,8'h46};
            'd143: i2c_data <= {16'h5191,8'hf8};
            'd144: i2c_data <= {16'h5192,8'h04};
            'd145: i2c_data <= {16'h5193,8'h70};
            'd146: i2c_data <= {16'h5194,8'hf0};
            'd147: i2c_data <= {16'h5195,8'hf0};
            'd148: i2c_data <= {16'h5196,8'h03};
            'd149: i2c_data <= {16'h5197,8'h01};
            'd150: i2c_data <= {16'h5198,8'h04};
            'd151: i2c_data <= {16'h5199,8'h12};
            'd152: i2c_data <= {16'h519a,8'h04};
            'd153: i2c_data <= {16'h519b,8'h00};
            'd154: i2c_data <= {16'h519c,8'h06};
            'd155: i2c_data <= {16'h519d,8'h82};
            'd156: i2c_data <= {16'h519e,8'h38};
            // Gamma(伽马)控制 16'h5480~16'h5490
            'd157: i2c_data <= {16'h5480,8'h01}; 
            'd158: i2c_data <= {16'h5481,8'h08};
            'd159: i2c_data <= {16'h5482,8'h14};
            'd160: i2c_data <= {16'h5483,8'h28};
            'd161: i2c_data <= {16'h5484,8'h51};
            'd162: i2c_data <= {16'h5485,8'h65};
            'd163: i2c_data <= {16'h5486,8'h71};
            'd164: i2c_data <= {16'h5487,8'h7d};
            'd165: i2c_data <= {16'h5488,8'h87};
            'd166: i2c_data <= {16'h5489,8'h91};
            'd167: i2c_data <= {16'h548a,8'h9a};
            'd168: i2c_data <= {16'h548b,8'haa};
            'd169: i2c_data <= {16'h548c,8'hb8};
            'd170: i2c_data <= {16'h548d,8'hcd};
            'd171: i2c_data <= {16'h548e,8'hdd};
            'd172: i2c_data <= {16'h548f,8'hea};
            'd173: i2c_data <= {16'h5490,8'h1d};
            // CMX(彩色矩阵控制) 16'h5381~16'h538b
            'd174: i2c_data <= {16'h5381,8'h1e};
            'd175: i2c_data <= {16'h5382,8'h5b};
            'd176: i2c_data <= {16'h5383,8'h08};
            'd177: i2c_data <= {16'h5384,8'h0a};
            'd178: i2c_data <= {16'h5385,8'h7e};
            'd179: i2c_data <= {16'h5386,8'h88};
            'd180: i2c_data <= {16'h5387,8'h7c};
            'd181: i2c_data <= {16'h5388,8'h6c};
            'd182: i2c_data <= {16'h5389,8'h10};
            'd183: i2c_data <= {16'h538a,8'h01};
            'd184: i2c_data <= {16'h538b,8'h98};
            // SDE(特殊数码效果)控制 16'h5580~16'h558b
            'd185: i2c_data <= {16'h5580,8'h06};
            'd186: i2c_data <= {16'h5583,8'h40};
            'd187: i2c_data <= {16'h5584,8'h10};
            'd188: i2c_data <= {16'h5589,8'h10};
            'd189: i2c_data <= {16'h558a,8'h00};
            'd190: i2c_data <= {16'h558b,8'hf8};
            'd191: i2c_data <= {16'h501d,8'h40}; // ISP MISC
            // CIP(颜色插值)控制 (16'h5300~16'h530c)
            'd192: i2c_data <= {16'h5300,8'h08};
            'd193: i2c_data <= {16'h5301,8'h30};
            'd194: i2c_data <= {16'h5302,8'h10};
            'd195: i2c_data <= {16'h5303,8'h00};
            'd196: i2c_data <= {16'h5304,8'h08};
            'd197: i2c_data <= {16'h5305,8'h30};
            'd198: i2c_data <= {16'h5306,8'h08};
            'd199: i2c_data <= {16'h5307,8'h16};
            'd200: i2c_data <= {16'h5309,8'h08};
            'd201: i2c_data <= {16'h530a,8'h30};
            'd202: i2c_data <= {16'h530b,8'h04};
            'd203: i2c_data <= {16'h530c,8'h06};
            'd204: i2c_data <= {16'h5025,8'h00};
            // 系统时钟分频 Bit[7:4]:系统时钟分频 input clock =24Mhz, PCLK = 48Mhz
            'd205: i2c_data <= {16'h3035,8'h11}; 
            'd206: i2c_data <= {16'h3036,8'h3c}; // PLL倍频
            'd207: i2c_data <= {16'h3c07,8'h08};
            // 时序控制 16'h3800~16'h3821
            'd208: i2c_data <= {16'h3820,8'h46};
            'd209: i2c_data <= {16'h3821,8'h01};
            'd210: i2c_data <= {16'h3814,8'h31};
            'd211: i2c_data <= {16'h3815,8'h31};
            'd212: i2c_data <= {16'h3800,8'h00};
            'd213: i2c_data <= {16'h3801,8'h00};
            'd214: i2c_data <= {16'h3802,8'h00};
            'd215: i2c_data <= {16'h3803,8'h04};
            'd216: i2c_data <= {16'h3804,8'h0a};
            'd217: i2c_data <= {16'h3805,8'h3f};
            'd218: i2c_data <= {16'h3806,8'h07};
            'd219: i2c_data <= {16'h3807,8'h9b};
            // 设置输出像素个数
            // DVP 输出水平像素点数高4位
            'd220: i2c_data <= {16'h3808,{4'd0,cam_h_pixel[11:8]}};
            // DVP 输出水平像素点数低8位
            'd221: i2c_data <= {16'h3809,cam_h_pixel[7:0]};
            // DVP 输出垂直像素点数高3位
            'd222: i2c_data <= {16'h380a,{5'd0,cam_v_pixel[10:8]}};
            // DVP 输出垂直像素点数低8位
            'd223: i2c_data <= {16'h380b,cam_v_pixel[7:0]};
            // 水平总像素大小高5位
            'd224: i2c_data <= {16'h380c,{3'd0,total_h_pixel[12:8]}};
            // 水平总像素大小低8位 
            'd225: i2c_data <= {16'h380d,total_h_pixel[7:0]};
            // 垂直总像素大小高5位 
            'd226: i2c_data <= {16'h380e,{3'd0,total_v_pixel[12:8]}};
            // 垂直总像素大小低8位     
            'd227: i2c_data <= {16'h380f,total_v_pixel[7:0]};
            'd228: i2c_data <= {16'h3813,8'h06};
            'd229: i2c_data <= {16'h3618,8'h00};
            'd230: i2c_data <= {16'h3612,8'h29};
            'd231: i2c_data <= {16'h3709,8'h52};
            'd232: i2c_data <= {16'h370c,8'h03};
            'd233: i2c_data <= {16'h3a02,8'h17}; // 60Hz max exposure
            'd234: i2c_data <= {16'h3a03,8'h10}; // 60Hz max exposure
            'd235: i2c_data <= {16'h3a14,8'h17}; // 50Hz max exposure
            'd236: i2c_data <= {16'h3a15,8'h10}; // 50Hz max exposure
            'd237: i2c_data <= {16'h4004,8'h02}; // BLC(背光) 2 lines
            'd238: i2c_data <= {16'h4713,8'h03}; // JPEG mode 3
            'd239: i2c_data <= {16'h4407,8'h04}; // 量化标度
            'd240: i2c_data <= {16'h460c,8'h22};     
            'd241: i2c_data <= {16'h4837,8'h22}; // DVP CLK divider
            'd242: i2c_data <= {16'h3824,8'h02}; // DVP CLK divider
            'd243: i2c_data <= {16'h5001,8'ha3}; // ISP 控制
            'd244: i2c_data <= {16'h3b07,8'h0a}; // 帧曝光模式  
            // 彩条测试使能 
            'd245: i2c_data <= {16'h503d,8'h00}; // 8'h00:正常模式 8'h80:彩条显示
            // 测试闪光灯功能
            'd246: i2c_data <= {16'h3016,8'h02};
            'd247: i2c_data <= {16'h301c,8'h02};
            'd248: i2c_data <= {16'h3019,8'h02}; // 打开闪光灯
            'd249: i2c_data <= {16'h3019,8'h00}; // 关闭闪光灯
            // 只读存储器,防止在case中没有列举的情况，之前的寄存器被重复改写
            default : i2c_data <= {16'h300a,8'h00}; // 器件ID高8位
        endcase
    end
end

endmodule