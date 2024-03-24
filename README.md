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

代码中三个通道分别进行编码，主要是输入一个PCLK，数据和同步  

子模块encoder负责8b/10b的转换，是Xilinx的代码  
子模块serializer是并转串行，十位转一位，采用两个Oserdes级联  
ddr数据模式，需要PLL5倍的PCLK输入  
最后在TOP用OBUFDS完成单端转差分，在物理层输出  

## AXI4
### 概述
AXI是AMBA第三代总线，第一代APB，第二代AHB  
AXI的拓展是ACE，下一代AXI5，这里只对AXI4作出探索
在我的理解中，AXI4是一种双向可靠高速片内传输总线，握手是它的核心思想  
发送方“能够发送”时，拉高valid了，接收方“能够接收”时，拉高ready  
只有两方互相确认传输的能力后，传输才会发起，这严格保障了传输的可靠性  
同时，AXI分为memory mapped和stream两种方式
前者分为LITE和最常见的FULL接口，为地址映射的可靠传输方式
后者常用于流式传输中，不给地址，不告诉数量，只有last作为“阀门”  
AXI中，总线双方必须共用一个总线时钟ACLK，跨时钟域时需要提前安排FIFO  
  
### 架构
基于以上机制，AXI总线总共有五个通道，分别负责不同流向的数据以及地址控制  
读地址 （AR） read address  
读数据 （R） read data  
写地址 （AW） write address  
写数据 （W） write data  
写回复 （R） write response  
#### 写传输
1. 主机在写地址通道上告知burst内容长度以及address
2. 在写数据通道上对齐传输数据
3. 从机接收到Wlast后再写回复通道上回复主机
#### 读传输
1. 主机在读地址通道上告知burst内容长度以及address
2. 在读数据通道上对齐传输数据
### Burst
在一段时间中，连续地传输多个（地址相邻的）数据  
每个传输事务有一至多个burst，每个burst有多个transfer  
主机首先将接下来burst传输的控制信息以及数据首个字节的地址传输给从机  
这个地址是起始地址，在本次 burst 后续传输期间，从机将根据控制信息计算后续数据的地址  
单次burst传输中的数据，其地址不能跨越4KB边界
burst length，指一次突发传输中包含的数据传输(transfer)数量，由Axlen控制  
在AXI4中，INCR类型最大支持长度为256，其他类型最大长度为16  
协议中的AxLen信号从零开始表示，实际的长度值为AxLEN+1  
一次突发传输不能在完成所有数据传输前提前结束  
burst size指传输中的数据位宽，是每周期传输数据的字节数量，在协议中使用AxSIZE信号控制  
传输宽度 = 2^AXSIZE  
AxBURST，类型共有3种，分别为 FIXED，INCR 以及 WRAP  
INCR 类型最为常用，后续数据的地址在初始地址的基础上进行递增，递增幅度与传输宽度相同  
Narrow Transfer，窄位宽写传输，主机告知从机数据通道中哪些字节是有效的，需要使用写数据通道中的WSTRB  
读写传输事务都存在2bit位宽的回复信号 RRESP/BRESP  
OKAY ，常规访问成功  
EXOKAY，独占访问成功  
SLVERR，从机错误，从机接收到了访问请求，向主机返回了一个错误状态，包括以下错误场景：  
  1 FIFO 或者缓冲区溢出  
  2 主机发起了不支持的传输位宽  
  3 尝试向读保护的地址写入数据  
  4 超时  
DECERR，解码错误，一表示主机发送的传输事务地址无效，无法将传输事务发送给某个从机    
### FPGA中的应用
在RTL代码中，主要实现了两个实例，一是对摄像头数据输出封装，二是对DDR输入输出的数据进行封装  
myip_v1_0_M00_AXI.v 是实现AXI主机的核心代码，其中M00表示ID号  
参数计算中详尽计算了各个长度、大小、位宽、数量  
主代码中各个通道严格遵循握手原则，使用valid和ready控制传输是否进行  
整套代码将摄像头接口封装成一个主机，用于对下游的memory模块进行有地址的写  
而myip_v1_0.v中实现了将摄像头数据和控制信号通过异步FIFO以及多bit cdc打拍来从PCLK同步到ACLK时钟域  
留出位宽参数的设置接口，将frame数据16位转ddr标准32位输出  
  























