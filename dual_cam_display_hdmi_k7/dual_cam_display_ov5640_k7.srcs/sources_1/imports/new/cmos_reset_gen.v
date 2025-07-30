`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/24 08:06:58
// Design Name: 
// Module Name: cmos_reset_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module cmos_reset_gen
        (
       input clk,
       input reset,
       output camera_rstn
        );                  

reg [18:0]cnt1;
reg [15:0]cnt2;

reg camera_rstn_reg;
reg camera_pwnd_reg;

assign camera_rstn=camera_rstn_reg;

//   5ms delay
always@(posedge clk)
begin
    if(reset==1'b1) begin
        cnt1<=0;
    end
    else if(cnt1<18'h40000) begin
       cnt1<=cnt1+1'b1;
    end
    else begin
        cnt1<=cnt1; 
    end        
end
//   5ms delay
always@(posedge clk)
begin
    if(reset==1'b1) begin
        camera_pwnd_reg<=1'b1;  
    end
    else if(cnt1<18'h40000) begin
        camera_pwnd_reg<=1'b1;
    end
    else begin
        camera_pwnd_reg<=1'b0;
    end       
end


//1.3ms delay
always@(posedge clk)
begin
  if(camera_pwnd_reg==1)  begin
        cnt2<=0;
  end
  else if(cnt2<16'hffff) begin
       cnt2<=cnt2+1'b1;
  end
  else begin
        cnt2<=cnt2;
  end 
     
end

//1.3ms delay
always@(posedge clk)
begin
    if(camera_pwnd_reg==1)  begin
        camera_rstn_reg<=1'b0;  
    end
    else if(cnt2<16'hffff) begin
       camera_rstn_reg<=1'b0;
    end
    else begin
        camera_rstn_reg<=1'b1;
    end         
end

endmodule

