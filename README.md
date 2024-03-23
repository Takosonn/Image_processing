# 图像处理的学习与尝试

关于 FPGA，Cemera，DDR，HDMI，AXI4，部分 Deep Learning 内容


## OV5640
### 配置  
RTL代码用于配置OV5640以及进行数据和行场同步接收  
OV5640需要sccb接口进行配置，其实就是一个I2C的时序  
OV5640的寄存器位数是16位
scl时钟配置成250khz，总共需要配置250个寄存器  
OV5640上电到开始配置IIC至少等待20ms  
先对寄存器进行软件复位，使寄存器恢复初始值  
寄存器软件复位后，需要延时1ms才能配置其它寄存器  
输出像素格式可以为  
YUV444, YUV422, YUV420  
RGB555, RGB565, RGB444, RGB888  
RAW 一般配置为RGB565，刚好16位  
### 数据传输
关键信号有  
          cam_pclk            // 数据像素时钟 来自ov5640  
          cam_vsync           // 场同步信号 来自ov5640  
          cam_href            // 行同步信号 来自ov5640  
 [7:0]    cam_data            // 摄像头数据 来自ov5640  
 摄像头每1个PCLK输出8位图像数据，每2个PCLK输出一位完整像素16位RGB565  
 通过FPGA将其转化为完整16位输出到下游模块  
 R4 R3 R2 R1 R0 G5 G4 G3; G2 G1 G0 B4 B3 B2 B1 B0;  
 行同步信号href和场同步信号vsync都是脉冲输出  
 代码中从第8帧开始算有效数据，舍弃前7帧后拉高帧有效  
 数据由AXI模块转化为标准AXI4_FULL格式输出  
 
## HDMI
### 概述
理论上HDMI 2.1可以达到48Gbps的恐怖带宽，但这里我只对FPGA实现1.0作出尝试  
HDMI2.0也许需要通过PHY芯片或者收发器去实现，有待以后探索  
HDMI兼容DVI，区别是HDMI还可以传输音频  
HDMI的精髓就在实现三个通道，含有8位RGB以及同步信号和控制信号  
TMDS编码技术是实现了DC平衡的编码，8b/10b  
首先实现VGA的时序，然后将data和同步送入rgb to dvi模块，转成dvi接口后输出  
### dvi接口实现
input        pclk,           // pixel clock  
input        pclk_x5,        // pixel clock x5  
input        reset_n,        // reset  
input [23:0] video_din,      // RGB888 video in  
input        video_hsync,    // hsync data  
input        video_vsync,    // vsync data  
input        video_de,       // data enable  
output       tmds_clk_p,    // TMDS 时钟通道  
output       tmds_clk_n,  
output [2:0] tmds_data_p,   // TMDS 数据通道  
output [2:0] tmds_data_n,  
output       tmds_oen       // TMDS 输出使能  
