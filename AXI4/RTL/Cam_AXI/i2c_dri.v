`timescale 1ns / 1ns

module i2c_dri
#(
    parameter   SLAVE_ADDR = 7'b011_1100      ,     // ov5640从机地址7'h3c
    parameter   CLK_FREQ   = 26'd50_000_000   ,     // 模块输入的时钟频率
    parameter   I2C_FREQ   = 18'd250_000            // i2c_SCL的时钟频率
)
(                                                            
    input                cam_clk        ,    
    input                i2c_dri_rst    ,                                 
    // i2c 接口                      
    input                i2c_exec       ,  // I2C触发执行信号
    input                i2c_rh_wl      ,  // I2C读写控制信号
    input        [15:0]  i2c_addr       ,  // I2C器件内地址
    input        [7:0]   i2c_data_w     ,  // I2C要写的数据
    output  reg  [7:0]   i2c_data_r     ,  // I2C读出的数据
    output  reg          i2c_done       ,  // I2C一次操作完成
    output  reg          i2c_ack        ,  // I2C应答标志 0:应答 1:未应答
    output  reg          i2c_scl        ,  // I2C的i2c_SCL时钟信号
    inout                i2c_sda        ,  // I2C的SDA信号
    output  reg          i2c_dri_clk       // 驱动I2C操作的驱动时钟
);

/******************************************** Parameter Define ***********************************************************/
localparam  IDLE    = 3'b000,   // 空闲状态
            S_ADDR  = 3'b001,   // 发送器件地址(slave address)
            ADDR_M8 = 3'b011,   // 发送高8位字地址
            ADDR_L8 = 3'b010,   // 发送低8位字地址
            DATA_WR = 3'b110,   // 写数据(8 bit)
            ADDR_RD = 3'b111,   // 发送器件地址读
            DATA_RD = 3'b101,   // 读数据(8 bit)
            DONE    = 3'b100;   // 结束I2C操作

localparam  [8:0] CLK_DEVIDE = (CLK_FREQ/I2C_FREQ) >> 2'd2;   // 模块驱动时钟的分频系数

/******************************************** Reg Define *****************************************************************/
reg            sda_dir   ;  // I2C数据(SDA)方向控制
reg            sda_out   ;  // SDA输出信号

reg    [6:0]   dri_cnt   ;  // 计数
reg    [9:0]   clk_cnt   ;  // 分频时钟计数

reg    [15:0]  r_addr    ;  // 地址
reg    [7:0]   r_data_r  ;  // 读取的数据
reg    [7:0]   r_data_w  ;  // I2C需写的数据的临时寄存


reg    [2:0]   curr_state;  // 状态机当前状态
reg    [2:0]   next_state;  // 状态机下一状态
reg            st_done   ;  // 状态结束

/******************************************** Wire Define ****************************************************************/
wire          sda_in     ;  // SDA输入信号


/******************************************** Continuous Assignments *****************************************************/
assign  i2c_sda = sda_dir ? sda_out : 'bz;          // SDA数据输出或高阻
assign  sda_in  = i2c_sda ;                         // SDA数据输入

/******************************************** Procedural Assignments *****************************************************/
// 生成I2C的i2c_SCL的四倍频率的驱动时钟用于驱动i2c的操作
always @(posedge cam_clk) begin
    if(i2c_dri_rst) begin
        clk_cnt     <= 'd0;
        i2c_dri_clk <= 'd0;
    end
    else if(clk_cnt >= CLK_DEVIDE[8:1] - 1) begin
        clk_cnt     <= 'd0;
        i2c_dri_clk <= ~i2c_dri_clk;
    end
    else
        clk_cnt     <= clk_cnt + 1;
end

/******************************************** Three Process FSM ***********************************************************/
always @(posedge i2c_dri_clk) begin
    if(i2c_dri_rst)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

always @(*) begin
    if(i2c_dri_rst)
        next_state <= IDLE;
    case(curr_state)
        IDLE    : next_state <= (i2c_exec) ? S_ADDR  : IDLE     ;
        S_ADDR  : next_state <= (st_done)  ? ADDR_M8 : S_ADDR   ;
        ADDR_M8 : next_state <= (st_done)  ? ADDR_L8 : ADDR_M8  ;
        ADDR_L8 : begin if(st_done)
                            next_state <= (i2c_rh_wl) ? ADDR_RD : DATA_WR ;    // 读写判断
                        else    
                            next_state <= ADDR_L8;
        end
        DATA_WR : next_state <= (st_done)  ? DONE    : DATA_WR  ;
        ADDR_RD : next_state <= (st_done)  ? DATA_RD : ADDR_RD  ;
        DATA_RD : next_state <= (st_done)  ? DONE    : DATA_RD  ;
        DONE    : next_state <= (st_done)  ? IDLE    : DONE     ;
        default : next_state <= IDLE;
    endcase
end

always @(posedge i2c_dri_clk) begin
    if(i2c_dri_rst) begin        
        i2c_scl     <= 'd1;
        sda_out     <= 'd1;
        sda_dir     <= 'd1;                          
        i2c_done    <= 'd0;                          
        i2c_ack     <= 'd0;                          
        dri_cnt     <= 'd0;                          
        st_done     <= 'd0;                          
        r_data_r    <= 'd0;                          
        i2c_data_r  <= 'd0;                                                    
        r_addr      <= 'd0;                          
        r_data_w    <= 'd0;                          
    end                                              
    else begin     
        st_done     <= 'd0;                            
        dri_cnt     <= dri_cnt + 1;                       
        case(curr_state)                              
            IDLE    : begin         
                        i2c_scl     <= 'd1;                                
                        sda_out     <= 'd1;                     
                        sda_dir     <= 'd1;                     
                        i2c_done    <= 'd0;                     
                        dri_cnt     <= 'd0;                                       
                        r_addr      <= i2c_exec ? i2c_addr   : 'd0;         
                        r_data_w    <= i2c_exec ? i2c_data_w : 'd0;  
                        i2c_ack     <= i2c_exec ? 'd0        : i2c_ack;                          
            end                                      
            S_ADDR  : begin                         // 写地址(器件地址和字地址)
                case(dri_cnt)                            
                    7'd1  : sda_out <= 'd0;         // 开始I2C
                    7'd3  : i2c_scl <= 'd0;              
                    7'd4  : sda_out <= SLAVE_ADDR[6];   // 传送器件地址
                    7'd5  : i2c_scl <= 'd1;              
                    7'd7  : i2c_scl <= 'd0;              
                    7'd8  : sda_out <= SLAVE_ADDR[5]; 
                    7'd9  : i2c_scl <= 'd1;              
                    7'd11 : i2c_scl <= 'd0;              
                    7'd12 : sda_out <= SLAVE_ADDR[4]; 
                    7'd13 : i2c_scl <= 'd1;              
                    7'd15 : i2c_scl <= 'd0;              
                    7'd16 : sda_out <= SLAVE_ADDR[3]; 
                    7'd17 : i2c_scl <= 'd1;              
                    7'd19 : i2c_scl <= 'd0;              
                    7'd20 : sda_out <= SLAVE_ADDR[2]; 
                    7'd21 : i2c_scl <= 'd1;              
                    7'd23 : i2c_scl <= 'd0;              
                    7'd24 : sda_out <= SLAVE_ADDR[1]; 
                    7'd25 : i2c_scl <= 'd1;              
                    7'd27 : i2c_scl <= 'd0;              
                    7'd28 : sda_out <= SLAVE_ADDR[0]; 
                    7'd29 : i2c_scl <= 'd1;              
                    7'd31 : i2c_scl <= 'd0;              
                    7'd32 : sda_out <= 'd0;          // 0:写
                    7'd33 : i2c_scl <= 'd1;              
                    7'd35 : i2c_scl <= 'd0;              
                    7'd36 : begin                     
                            sda_dir <= 'd0;             
                            sda_out <= 'd1;                         
                    end                              
                    7'd37 : i2c_scl <= 'd1;            
                    7'd38 : begin                     // 从机应答 
                            st_done <= 'd1;
                            i2c_ack <= (sda_in) ? 'd1 : 'd0;    // 拉高应答标志位     
                    end                                          
                    7'd39 : begin                     
                            i2c_scl <= 'd0;                 
                            dri_cnt <= 'd0;                 
                    end                              
                    default : ;                     
                endcase                              
            end                                      
            
            ADDR_M8 : begin                         
                case(dri_cnt)                            
                    7'd0  : begin                     
                            sda_dir <= 'd1;            
                            sda_out <= r_addr[15];       // 传送字地址
                    end                              
                    7'd1  : i2c_scl <= 'd1;              
                    7'd3  : i2c_scl <= 'd0;              
                    7'd4  : sda_out <= r_addr[14];    
                    7'd5  : i2c_scl <= 'd1;              
                    7'd7  : i2c_scl <= 'd0;              
                    7'd8  : sda_out <= r_addr[13];    
                    7'd9  : i2c_scl <= 'd1;              
                    7'd11 : i2c_scl <= 'd0;              
                    7'd12 : sda_out <= r_addr[12];    
                    7'd13 : i2c_scl <= 'd1;              
                    7'd15 : i2c_scl <= 'd0;              
                    7'd16 : sda_out <= r_addr[11];    
                    7'd17 : i2c_scl <= 'd1;              
                    7'd19 : i2c_scl <= 'd0;              
                    7'd20 : sda_out <= r_addr[10];    
                    7'd21 : i2c_scl <= 'd1;              
                    7'd23 : i2c_scl <= 'd0;              
                    7'd24 : sda_out <= r_addr[9];     
                    7'd25 : i2c_scl <= 'd1;              
                    7'd27 : i2c_scl <= 'd0;              
                    7'd28 : sda_out <= r_addr[8];     
                    7'd29 : i2c_scl <= 'd1;              
                    7'd31 : i2c_scl <= 'd0;              
                    7'd32 : begin                     
                            sda_dir <= 'd0;             
                            sda_out <= 'd1;   
                    end                              
                    7'd33 : i2c_scl <= 'd1;             
                    7'd34 : begin                     // 从机应答
                            st_done <= 'd1;     
                            i2c_ack <= (sda_in) ? 'd1 : 'd0;    // 拉高应答标志位
                    end        
                    7'd35: begin                     
                            i2c_scl <= 'd0;                 
                            dri_cnt <= 'd0;                 
                    end                              
                    default : ;                     
                endcase                              
            end                                      
            ADDR_L8 : begin                          
                case(dri_cnt)                            
                    7'd0 : begin                      
                            sda_dir <= 1'b1 ;             
                            sda_out <= r_addr[7];         // 字地址
                    end                              
                    7'd1  : i2c_scl <= 'd1;              
                    7'd3  : i2c_scl <= 'd0;              
                    7'd4  : sda_out <= r_addr[6];     
                    7'd5  : i2c_scl <= 'd1;              
                    7'd7  : i2c_scl <= 'd0;              
                    7'd8  : sda_out <= r_addr[5];     
                    7'd9  : i2c_scl <= 'd1;              
                    7'd11 : i2c_scl <= 'd0;              
                    7'd12 : sda_out <= r_addr[4];     
                    7'd13 : i2c_scl <= 'd1;              
                    7'd15 : i2c_scl <= 'd0;              
                    7'd16 : sda_out <= r_addr[3];     
                    7'd17 : i2c_scl <= 'd1;              
                    7'd19 : i2c_scl <= 'd0;              
                    7'd20 : sda_out <= r_addr[2];     
                    7'd21 : i2c_scl <= 'd1;              
                    7'd23 : i2c_scl <= 'd0;              
                    7'd24 : sda_out <= r_addr[1];     
                    7'd25 : i2c_scl <= 'd1;              
                    7'd27 : i2c_scl <= 'd0;              
                    7'd28 : sda_out <= r_addr[0];     
                    7'd29 : i2c_scl <= 'd1;              
                    7'd31 : i2c_scl <= 'd0;              
                    7'd32 : begin                     
                            sda_dir <= 'd0;         
                            sda_out <= 'd1;                    
                    end                              
                    7'd33 : i2c_scl <= 'd1;          
                    7'd34 : begin                        // 从机应答
                            st_done <= 'd1;        
                            i2c_ack <= (sda_in) ? 'd1 : 'd0;    // 拉高应答标志位 
                    end   
                    7'd35: begin                     
                            i2c_scl <= 'd0;                 
                            dri_cnt <= 'd0;                 
                    end                              
                    default : ;                     
                endcase                              
            end                                    

            DATA_WR : begin                             // 写数据(8 bit)
                case(dri_cnt)                            
                    7'd0 : begin                      
                            sda_out <= r_data_w [7];        // I2C写8位数据
                            sda_dir <= 'd1;             
                    end                              
                    7'd1  : i2c_scl <= 'd1;              
                    7'd3  : i2c_scl <= 'd0;              
                    7'd4  : sda_out <= r_data_w[6];  
                    7'd5  : i2c_scl <= 'd1;             
                    7'd7  : i2c_scl <= 'd0;             
                    7'd8  : sda_out <= r_data_w[5];  
                    7'd9  : i2c_scl <= 'd1;             
                    7'd11 : i2c_scl <= 'd0;             
                    7'd12 : sda_out <= r_data_w[4];  
                    7'd13 : i2c_scl <= 'd1;             
                    7'd15 : i2c_scl <= 'd0;             
                    7'd16 : sda_out <= r_data_w[3];  
                    7'd17 : i2c_scl <= 'd1;             
                    7'd19 : i2c_scl <= 'd0;             
                    7'd20 : sda_out <= r_data_w[2];  
                    7'd21 : i2c_scl <= 'd1;             
                    7'd23 : i2c_scl <= 'd0;             
                    7'd24 : sda_out <= r_data_w[1];  
                    7'd25 : i2c_scl <= 'd1;             
                    7'd27 : i2c_scl <= 'd0;             
                    7'd28 : sda_out <= r_data_w[0];  
                    7'd29 : i2c_scl <= 'd1;              
                    7'd31 : i2c_scl <= 'd0;              
                    7'd32 : begin                     
                            sda_dir <= 'd0;           
                            sda_out <= 'd1;                              
                    end                              
                    7'd33 : i2c_scl <= 'd1;              
                    7'd34 : begin                     // 从机应答
                            st_done <= 'd1;     
                            i2c_ack <= (sda_in) ? 'd1 : 'd0;    // 拉高应答标志位     
                    end          
                    7'd35 : begin                     
                            i2c_scl <= 'd0;                
                            dri_cnt  <= 'd0;                
                    end                              
                    default : ;                    
                endcase                              
            end                                      
            ADDR_RD : begin                        // 写地址以进行读数据
                case(dri_cnt)                            
                    7'd0  : begin                     
                            sda_dir <= 'd1;             
                            sda_out <= 'd1;             
                    end                              
                    7'd1  : i2c_scl <= 'd1;              
                    7'd2  : sda_out <= 'd0;             // 重新开始
                    7'd3  : i2c_scl <= 'd0;              
                    7'd4  : sda_out <= SLAVE_ADDR[6];   // 传送器件地址
                    7'd5  : i2c_scl <= 'd1;              
                    7'd7  : i2c_scl <= 'd0;              
                    7'd8  : sda_out <= SLAVE_ADDR[5]; 
                    7'd9  : i2c_scl <= 'd1;              
                    7'd11 : i2c_scl <= 'd0;              
                    7'd12 : sda_out <= SLAVE_ADDR[4]; 
                    7'd13 : i2c_scl <= 'd1;              
                    7'd15 : i2c_scl <= 'd0;              
                    7'd16 : sda_out <= SLAVE_ADDR[3]; 
                    7'd17 : i2c_scl <= 'd1;              
                    7'd19 : i2c_scl <= 'd0;              
                    7'd20 : sda_out <= SLAVE_ADDR[2]; 
                    7'd21 : i2c_scl <= 'd1;              
                    7'd23 : i2c_scl <= 'd0;              
                    7'd24 : sda_out <= SLAVE_ADDR[1]; 
                    7'd25 : i2c_scl <= 'd1;              
                    7'd27 : i2c_scl <= 'd0;              
                    7'd28 : sda_out <= SLAVE_ADDR[0]; 
                    7'd29 : i2c_scl <= 'd1;              
                    7'd31 : i2c_scl <= 'd0;              
                    7'd32 : sda_out <= 'd1;          // 1:读
                    7'd33 : i2c_scl <= 'd1;              
                    7'd35 : i2c_scl <= 'd0;              
                    7'd36 : begin                     
                            sda_dir <= 'd0;            
                            sda_out <= 'd1;                    
                    end
                    7'd37 : i2c_scl <= 'd1;
                    7'd38 : begin                     // 从机应答
                            st_done <= 'd1;     
                            i2c_ack <= (sda_in) ? 'd1 : 'd0;    // 拉高应答标志位     
  
                    end   
                    7'd39 : begin
                            i2c_scl <= 'd0;
                            dri_cnt <= 'd0;
                    end
                    default : ;
                endcase
            end
            DATA_RD : begin                     // 读取数据(8 bit)
                case(dri_cnt)
                    7'd0  : sda_dir <= 'd0;
                    7'd1  : begin
                            i2c_scl <= 'd1;
                            r_data_r[7] <= sda_in;
                    end  
                    7'd3  : i2c_scl <= 'd0;
                    7'd5  : begin
                            i2c_scl <= 'd1;
                            r_data_r[6] <= sda_in;
                    end  
                    7'd7  : i2c_scl <= 'd0;
                    7'd9  : begin
                            i2c_scl <= 'd1;
                            r_data_r[5] <= sda_in;
                    end
                    7'd11 : i2c_scl <= 'd0;
                    7'd13 : begin
                            i2c_scl <= 'd1;
                            r_data_r[4] <= sda_in;
                    end 
                    7'd15 : i2c_scl <= 'd0;
                    7'd17 : begin
                            i2c_scl <= 'd1;
                            r_data_r[3] <= sda_in;
                    end 
                    7'd19 : i2c_scl <= 'd0;
                    7'd21 : begin
                            i2c_scl <= 'd1;
                            r_data_r[2] <= sda_in;
                    end 
                    7'd23 : i2c_scl <= 'd0;
                    7'd25 : begin
                            i2c_scl <= 'd1;
                            r_data_r[1] <= sda_in;
                    end 
                    7'd27 : i2c_scl <= 'd0;
                    7'd29 : begin
                            i2c_scl <= 'd1;
                            r_data_r[0] <= sda_in;
                    end 
                    7'd31 : i2c_scl <= 'd0;
                    7'd32 : begin
                            sda_dir <= 'd1;             
                            sda_out <= 'd1;
                    end 
                    7'd33 : i2c_scl <= 'd1;
                    7'd34 : st_done <= 'd1;          // 非应答
                    7'd35 : begin
                            i2c_scl <= 'd0;
                            dri_cnt <= 'd0;
                            i2c_data_r <= r_data_r;
                    end
                    default : ;
                endcase
            end 
            DONE : begin                            // 结束I2C操作
                case(dri_cnt)
                    7'd0: begin
                            sda_dir <= 'd1;     // 结束I2C
                            sda_out <= 'd0;
                    end
                    7'd1  : i2c_scl <= 'd1;
                    7'd3  : sda_out <= 'd1;
                    7'd15 : st_done <= 'd1;
                    7'd16 : begin
                            dri_cnt <= 'd0;
                            i2c_done <= 'd1;   // 向上层模块传递I2C结束信号
                    end
                    default : ;
                endcase
            end
            default : ;
        endcase
    end
end

endmodule
