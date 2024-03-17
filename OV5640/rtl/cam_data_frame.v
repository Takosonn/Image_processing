`timescale 1ns / 1ns

module cam_data_frame
(
    input               cam_data_asy_rst    ,     
    // 摄像头接口                           
    input               cam_pclk            ,  // 数据像素时钟 来自ov5640
    input               cam_vsync           ,  // 场同步信号 来自ov5640
    input               cam_href            ,  // 行同步信号 来自ov5640
    input      [7:0]    cam_data            ,  // 摄像头数据 来自ov5640                    
    // 用户接口                              
    output              cam_frame_vsync     ,  // 帧有效信号    
    output              cam_frame_href      ,  // 行有效信号
    output              cam_frame_valid     ,  // 数据有效信号
    output reg [15:0]   cam_frame_data      ,  // 有效数据 RGB888
    output reg          cam_frame_dclk  
);

/******************************************** Parameter Define ***********************************************************/
// 寄存器全部配置完成后，先等待7帧数据
// 待寄存器配置生效后再开始采集图像
parameter  WAIT_FRAME = 3'd7    ;             // 寄存器数据稳定等待的帧个数            
							     
/******************************************** Reg Define *****************************************************************/                    
reg             r_cam_vsync_0   ;
reg             r_cam_vsync_1   ;
reg             r_cam_href      ;
reg    [7:0]    r_cam_data      ;
reg    [2:0]    frame_cnt       ;             // 等待帧数稳定计数器

reg             data_valid      ;             // 16位RGB数据转换完成的标志信号
reg             frame_valid     ;             // 帧有效的标志 

/******************************************** Wire Define ****************************************************************/
wire            pulse_cam_vsync ;

/******************************************** Smart Reset ****************************************************************/
(*keep = "true"*)   reg     cam_data_rst_reg0    ;
(*keep = "true"*)   reg     cam_data_rst_reg1    ;
(*keep = "true"*)   wire    cam_data_rst         ;

always @(posedge cam_pclk or posedge cam_data_asy_rst) begin
    if(cam_data_asy_rst) begin
        cam_data_rst_reg0 <= 'd1;
        cam_data_rst_reg1 <= 'd1;
    end
    else begin
        cam_data_rst_reg0 <= 'd0;
        cam_data_rst_reg1 <= cam_data_rst_reg0;
    end
end

//local rst
assign  cam_data_rst = cam_data_rst_reg1;

/******************************************** Continuous Assignments *****************************************************/
// 场有效信号脉冲
assign  pulse_cam_vsync = (r_cam_vsync_0) && (!r_cam_vsync_1);

// 输出帧有效信号
assign  cam_frame_vsync = (frame_valid)  ?  pulse_cam_vsync :  'd0;

// 输出行有效信号
assign  cam_frame_href  = (frame_valid)  ?  r_cam_href      :  'd0;

// 输出数据使能有效信号
assign  cam_frame_valid = (frame_valid)  ?  data_valid      :  'd0;


/******************************************** Procedural Assignments *****************************************************/
// 打拍
always @(posedge cam_pclk) begin
    if(cam_data_rst) begin
        r_cam_vsync_0   <= 'd0;
        r_cam_vsync_1   <= 'd0;
        r_cam_href      <= 'd0;
    end
    else begin
        r_cam_vsync_0   <= cam_vsync;
        r_cam_vsync_1   <= r_cam_vsync_0;
        r_cam_href      <= cam_href;
    end
end

// 对帧数进行计数
always @(posedge cam_pclk) begin
    if(cam_data_rst)
        frame_cnt <= 'd0;
    else if(pulse_cam_vsync && (frame_cnt < WAIT_FRAME))
        frame_cnt <= frame_cnt + 'd1;
    else
        frame_cnt <= frame_cnt;
end

// 帧有效标志 第8帧拉高
always @(posedge cam_pclk) begin
    if(cam_data_rst)
        frame_valid <= 'd0;
    else if((frame_cnt == WAIT_FRAME) && pulse_cam_vsync)
        frame_valid <= 'd1;
    else
        frame_valid <= frame_valid;
end            

// 8位数据转16位RGB565数据        
always @(posedge cam_pclk) begin
    if(cam_data_rst) begin
        r_cam_data      <= 'd0;
        data_valid      <= 'd0;
        cam_frame_data  <= 'd0;
        cam_frame_dclk  <= 'd0;

    end
    else if(cam_href) begin
        data_valid      <= ~data_valid;
        r_cam_data      <= cam_data;    // R4 R3 R2 R1 R0 G5 G4 G3; // G2 G1 G0 B4 B3 B2 B1 B0;
        
        cam_frame_data  <= (data_valid) ?
                                        {
                                            r_cam_data,cam_data                             // RGB565
                                        }
                                        //{
                                        //    r_cam_data[7:3],r_cam_data[5:3],                // R
                                        //    r_cam_data[2:0],cam_data[7:5],cam_data[6:5],    // G
                                        //    cam_data[4:0],cam_data[2:0]                     // B
                                        //} 
                                        : cam_frame_data;  
    end
    else begin
        cam_frame_dclk  <= ~cam_frame_dclk;
        data_valid      <= 'd0;
        r_cam_data      <= 'd0;
        cam_frame_data  <= 'd0;
    end    
end

endmodule