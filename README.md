# 图像处理的学习与尝试

关于 FPGA，Cemera，DDR，HDMI，部分 Deep Learning 内容


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
          cam_frame_vsync     // 帧有效信号  
          cam_frame_href      // 行有效信号  
          cam_frame_valid     // 数据有效信号  
 [15:0]   cam_frame_data      // 有效数据 RGB888  
          cam_frame_dclk  
