module vga_driver(
    input           vga_clk,      //VGA时钟
    input           sys_rst_n,    
    //VGA interface                          
    output          vga_hs,       //行同步
    output          vga_vs,       //场同步
    output          vga_en,       //数据使能
    output  [15:0]  vga_rgb,      //rgb565数据

    input   [15:0]  pixel_data,   //像素点数据
    
    output          data_req  ,   //数据请求信号 
    output  [10:0]  pixel_xpos,   //像素点x坐标
    output  [10:0]  pixel_ypos    //像素点y坐标    
    );                             

//parameter define  
/*
//640*480 60FPS_25MHz
parameter  H_SYNC   =  10'd96;    //
parameter  H_BACK   =  10'd48;    //
parameter  H_DISP   =  10'd640;   //
parameter  H_FRONT  =  10'd16;    //
parameter  H_TOTAL  =  10'd800;   //

parameter  V_SYNC   =  10'd2;     //
parameter  V_BACK   =  10'd33;    //
parameter  V_DISP   =  10'd480;   //
parameter  V_FRONT  =  10'd10;    //
parameter  V_TOTAL  =  10'd525;   //
*/

//1024*768 60FPS_65MHz
parameter  H_SYNC   =  11'd136;   //行同步     
parameter  H_BACK   =  11'd160;   //行后延
parameter  H_DISP   =  11'd1024;  //有效数据
parameter  H_FRONT  =  11'd24;    //行显示前沿
parameter  H_TOTAL  =  11'd1344;  //行周期

parameter  V_SYNC   =  11'd6;     //场同步
parameter  V_BACK   =  11'd29;    //场显示后沿
parameter  V_DISP   =  11'd768;   //场有效数据
parameter  V_FRONT  =  11'd3;     //场显示前沿
parameter  V_TOTAL  =  11'd806;   //场扫描周期

//reg define                                     
reg  [10:0] cnt_h;               
reg  [10:0] cnt_v;


//*****************************************************
//**                    main code
//*****************************************************
//行场同步信号赋值
assign vga_hs  = (cnt_h >= H_DISP+H_FRONT) && (cnt_h <= H_DISP+H_FRONT+H_SYNC - 1'b1) ? 1'b1 : 1'b0;
assign vga_vs  = (cnt_v >= V_DISP+V_FRONT) && (cnt_v <= V_DISP+V_FRONT+V_SYNC - 1'b1) ? 1'b1 : 1'b0;

//使能rgb565数据输出
assign vga_en  = ((cnt_h < H_DISP)&&(cnt_v < V_DISP)) ?  1'b1 : 1'b0;
                 
//RGB565数据输出                 
assign vga_rgb = vga_en ? pixel_data : 16'd0;

//有效区域请求像素点颜色输入                
assign data_req = ((cnt_h < H_DISP) && (cnt_v < V_DISP)) ?  1'b1 : 1'b0;

//像素点坐标               
assign pixel_xpos = data_req ? cnt_h - 1'b1 : 10'd0;
assign pixel_ypos = data_req ? cnt_v - 1'b1 : 10'd0;

//行计数器对像素时钟计数
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        cnt_h <= 10'd0;                                  
    else begin
        if(cnt_h < H_TOTAL - 1'b1)                                               
            cnt_h <= cnt_h + 1'b1;                               
        else 
            cnt_h <= 10'd0;  
    end
end

//场计数器计数行
always @(posedge vga_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        cnt_v <= 10'd0;                                  
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)                                               
            cnt_v <= cnt_v + 1'b1;                               
        else 
            cnt_v <= 10'd0;  
    end
end

endmodule 