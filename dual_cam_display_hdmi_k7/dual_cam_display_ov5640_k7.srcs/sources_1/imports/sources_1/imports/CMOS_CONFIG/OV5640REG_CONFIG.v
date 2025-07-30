`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/02 18:05:16
// Design Name: 
// Module Name: OV5640REG_CONFIG
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


module OV5640REG_CONFIG(
	input  wire[9:0]   lut_index,   //Look-up table address
	output reg [31:0]  lut_data     //Device address (8bit I2C address), register address, register data
);

always@(*) begin
	case(lut_index)	
        //先对寄存器进行软件复位，使寄存器恢复初始值
        //寄存器软件复位后，需要延时1ms才能配置其它寄存器	
		10'd  0: lut_data <= {8'h78 , 24'h310311};
		10'd  1: lut_data <= {8'h78 , 24'h300882}; //Bit[7]:复位 Bit[6]:电源休眠
		10'd  2: lut_data <= {8'h78 , 24'h300842}; //正常工作模式
		10'd  3: lut_data <= {8'h78 , 24'h310303}; //Bit[1]:1 PLL Clock
		//引脚输入/输出控制 FREX/VSYNC/HREF/PCLK/D[9:6]
		10'd  4: lut_data <= {8'h78 , 24'h3017ff};
		//引脚输入/输出控制 D[5:0]/GPIO1/GPIO0 
		10'd  5: lut_data <= {8'h78 , 24'h3018ff};
		10'd  6: lut_data <= {8'h78 , 24'h30341A};
		10'd  7: lut_data <= {8'h78 , 24'h303713};//PLL分频控制
		10'd  8: lut_data <= {8'h78 , 24'h310801};//系统根分频器
		10'd  9: lut_data <= {8'h78 , 24'h363036};
		10'd 10: lut_data <= {8'h78 , 24'h36310e};
		10'd 11: lut_data <= {8'h78 , 24'h3632e2};
		10'd 12: lut_data <= {8'h78 , 24'h363312};
		10'd 13: lut_data <= {8'h78 , 24'h3621e0};
		10'd 14: lut_data <= {8'h78 , 24'h3704a0};
		10'd 15: lut_data <= {8'h78 , 24'h37035a};
		10'd 16: lut_data <= {8'h78 , 24'h371578};
		10'd 17: lut_data <= {8'h78 , 24'h371701};
		10'd 18: lut_data <= {8'h78 , 24'h370b60};
		10'd 19: lut_data <= {8'h78 , 24'h37051a};
		10'd 20: lut_data <= {8'h78 , 24'h390502};
		10'd 21: lut_data <= {8'h78 , 24'h390610};
		10'd 22: lut_data <= {8'h78 , 24'h39010a};
		10'd 23: lut_data <= {8'h78 , 24'h373112};
		10'd 24: lut_data <= {8'h78 , 24'h360008};//VCM控制,用于自动聚焦
		10'd 25: lut_data <= {8'h78 , 24'h360133};//VCM控制,用于自动聚焦
		10'd 26: lut_data <= {8'h78 , 24'h302d60};//系统控制
		10'd 27: lut_data <= {8'h78 , 24'h362052};
		10'd 28: lut_data <= {8'h78 , 24'h371b20};
		10'd 29: lut_data <= {8'h78 , 24'h471c50};
		10'd 30: lut_data <= {8'h78 , 24'h3a1343};//AEC(自动曝光控制)
		10'd 31: lut_data <= {8'h78 , 24'h3a1800};//AEC 增益上限
		10'd 32: lut_data <= {8'h78 , 24'h3a19f8};//AEC 增益上限
		10'd 33: lut_data <= {8'h78 , 24'h363513};
		10'd 34: lut_data <= {8'h78 , 24'h363603};
		10'd 35: lut_data <= {8'h78 , 24'h363440};
		10'd 36: lut_data <= {8'h78 , 24'h362201};
		10'd 37: lut_data <= {8'h78 , 24'h3c0134};
		10'd 38: lut_data <= {8'h78 , 24'h3c0428};
		10'd 39: lut_data <= {8'h78 , 24'h3c0598};
		10'd 40: lut_data <= {8'h78 , 24'h3c0600};//light meter 1 阈值[15:8]
		10'd 41: lut_data <= {8'h78 , 24'h3c0708};//light meter 1 阈值[7:0]
		10'd 42: lut_data <= {8'h78 , 24'h3c0800};//light meter 2 阈值[15:8]
		10'd 43: lut_data <= {8'h78 , 24'h3c091c};//light meter 2 阈值[7:0]
		10'd 44: lut_data <= {8'h78 , 24'h3c0a9c};//sample number[15:8]
		10'd 45: lut_data <= {8'h78 , 24'h3c0b40};//sample number[7:0]
		10'd 46: lut_data <= {8'h78 , 24'h381000};//Timing Hoffset[11:8]
		10'd 47: lut_data <= {8'h78 , 24'h381110};//Timing Hoffset[7:0]
		10'd 48: lut_data <= {8'h78 , 24'h381200};//Timing Voffset[10:8]
		10'd 49: lut_data <= {8'h78 , 24'h370864};
		10'd 50: lut_data <= {8'h78 , 24'h400102};//BLC(黑电平校准)补偿起始行号
		10'd 51: lut_data <= {8'h78 , 24'h40051a};//BLC(黑电平校准)补偿始终更新
		10'd 52: lut_data <= {8'h78 , 24'h300000};//系统块复位控制
		10'd 53: lut_data <= {8'h78 , 24'h3004ff};//时钟使能控制
		10'd 54: lut_data <= {8'h78 , 24'h300e58};
		10'd 55: lut_data <= {8'h78 , 24'h302e00};
		10'd 56: lut_data <= {8'h78 , 24'h430060};//格式控制 RGB565
		10'd 57: lut_data <= {8'h78 , 24'h501f01};//ISP RGB
		10'd 58: lut_data <= {8'h78 , 24'h440e00};
		10'd 59: lut_data <= {8'h78 , 24'h5000a7};//ISP控制
		10'd 60: lut_data <= {8'h78 , 24'h3a0f30};//AEC控制;stable range in high
		10'd 61: lut_data <= {8'h78 , 24'h3a1028};//AEC控制;stable range in low
		10'd 62: lut_data <= {8'h78 , 24'h3a1b30};//AEC控制;stable range out high
		10'd 63: lut_data <= {8'h78 , 24'h3a1e26};//AEC控制;stable range out low
		10'd 64: lut_data <= {8'h78 , 24'h3a1160};//AEC控制; fast zone high
		10'd 65: lut_data <= {8'h78 , 24'h3a1f14};//AEC控制; fast zone low
		//LENC(镜头校正)控制 16'h5800~16'h583d
		10'd 66: lut_data <= {8'h78 , 24'h580023};
		10'd 67: lut_data <= {8'h78 , 24'h580114};
		10'd 68: lut_data <= {8'h78 , 24'h58020f};
		10'd 69: lut_data <= {8'h78 , 24'h58030f};
		10'd 70: lut_data <= {8'h78 , 24'h580412};
		10'd 71: lut_data <= {8'h78 , 24'h580526};
		10'd 72: lut_data <= {8'h78 , 24'h58060c};
		10'd 73: lut_data <= {8'h78 , 24'h580708};
		10'd 74: lut_data <= {8'h78 , 24'h580805};
		10'd 75: lut_data <= {8'h78 , 24'h580905};
		10'd 76: lut_data <= {8'h78 , 24'h580a08};
		10'd 77: lut_data <= {8'h78 , 24'h580b0d};
		10'd 78: lut_data <= {8'h78 , 24'h580c08};
		10'd 79: lut_data <= {8'h78 , 24'h580d03};
		10'd 80: lut_data <= {8'h78 , 24'h580e00};
		10'd 81: lut_data <= {8'h78 , 24'h580f00};
		10'd 82: lut_data <= {8'h78 , 24'h581003};
		10'd 83: lut_data <= {8'h78 , 24'h581109};
		10'd 84: lut_data <= {8'h78 , 24'h581207};
		10'd 85: lut_data <= {8'h78 , 24'h581303};
		10'd 86: lut_data <= {8'h78 , 24'h581400};
		10'd 87: lut_data <= {8'h78 , 24'h581501};
		10'd 88: lut_data <= {8'h78 , 24'h581603};
		10'd 89: lut_data <= {8'h78 , 24'h581708};
		10'd 90: lut_data <= {8'h78 , 24'h58180d};
		10'd 91: lut_data <= {8'h78 , 24'h581908};
		10'd 92: lut_data <= {8'h78 , 24'h581a05};
		10'd 93: lut_data <= {8'h78 , 24'h581b06};
		10'd 94: lut_data <= {8'h78 , 24'h581c08};
		10'd 95: lut_data <= {8'h78 , 24'h581d0e};
		10'd 96: lut_data <= {8'h78 , 24'h581e29};
		10'd 97: lut_data <= {8'h78 , 24'h581f17};
		10'd 98: lut_data <= {8'h78 , 24'h582011};
		10'd 99: lut_data <= {8'h78 , 24'h582111};
		10'd100: lut_data <= {8'h78 , 24'h582215};
		10'd101: lut_data <= {8'h78 , 24'h582328};
		10'd102: lut_data <= {8'h78 , 24'h582446};
		10'd103: lut_data <= {8'h78 , 24'h582526};
		10'd104: lut_data <= {8'h78 , 24'h582608};
		10'd105: lut_data <= {8'h78 , 24'h582726};
		10'd106: lut_data <= {8'h78 , 24'h582864};
		10'd107: lut_data <= {8'h78 , 24'h582926};
		10'd108: lut_data <= {8'h78 , 24'h582a24};
		10'd109: lut_data <= {8'h78 , 24'h582b22};
		10'd110: lut_data <= {8'h78 , 24'h582c24};
		10'd111: lut_data <= {8'h78 , 24'h582d24};
		10'd112: lut_data <= {8'h78 , 24'h582e06};
		10'd113: lut_data <= {8'h78 , 24'h582f22};
		10'd114: lut_data <= {8'h78 , 24'h583040};
		10'd115: lut_data <= {8'h78 , 24'h583142};
		10'd116: lut_data <= {8'h78 , 24'h583224};
		10'd117: lut_data <= {8'h78 , 24'h583326};
		10'd118: lut_data <= {8'h78 , 24'h583424};
		10'd119: lut_data <= {8'h78 , 24'h583522};
		10'd120: lut_data <= {8'h78 , 24'h583622};
		10'd121: lut_data <= {8'h78 , 24'h583726};
		10'd122: lut_data <= {8'h78 , 24'h583844};
		10'd123: lut_data <= {8'h78 , 24'h583924};
		10'd124: lut_data <= {8'h78 , 24'h583a26};
		10'd125: lut_data <= {8'h78 , 24'h583b28};
		10'd126: lut_data <= {8'h78 , 24'h583c42};
		10'd127: lut_data <= {8'h78 , 24'h583dce};
		//AWB(自动白平衡控制) 16'h5180~16'h519e
		10'd128: lut_data <= {8'h78 , 24'h5180ff};
		10'd129: lut_data <= {8'h78 , 24'h5181f2};
		10'd130: lut_data <= {8'h78 , 24'h518200};
		10'd131: lut_data <= {8'h78 , 24'h518314};
		10'd132: lut_data <= {8'h78 , 24'h518425};
		10'd133: lut_data <= {8'h78 , 24'h518524};
		10'd134: lut_data <= {8'h78 , 24'h518609};
		10'd135: lut_data <= {8'h78 , 24'h518709};
		10'd136: lut_data <= {8'h78 , 24'h518809};
		10'd137: lut_data <= {8'h78 , 24'h518975};
		10'd138: lut_data <= {8'h78 , 24'h518a54};
		10'd139: lut_data <= {8'h78 , 24'h518be0};
		10'd140: lut_data <= {8'h78 , 24'h518cb2};
		10'd141: lut_data <= {8'h78 , 24'h518d42};
		10'd142: lut_data <= {8'h78 , 24'h518e3d};
		10'd143: lut_data <= {8'h78 , 24'h518f56};
		10'd144: lut_data <= {8'h78 , 24'h519046};
		10'd145: lut_data <= {8'h78 , 24'h5191f8};
		10'd146: lut_data <= {8'h78 , 24'h519204};
		10'd147: lut_data <= {8'h78 , 24'h519370};
		10'd148: lut_data <= {8'h78 , 24'h5194f0};
		10'd149: lut_data <= {8'h78 , 24'h5195f0};
		10'd150: lut_data <= {8'h78 , 24'h519603};
		10'd151: lut_data <= {8'h78 , 24'h519701};
		10'd152: lut_data <= {8'h78 , 24'h519804};
		10'd153: lut_data <= {8'h78 , 24'h519912};
		10'd154: lut_data <= {8'h78 , 24'h519a04};
		10'd155: lut_data <= {8'h78 , 24'h519b00};
		10'd156: lut_data <= {8'h78 , 24'h519c06};
		10'd157: lut_data <= {8'h78 , 24'h519d82};
		10'd158: lut_data <= {8'h78 , 24'h519e38};
		//Gamma(伽马)控制 16'h5480~16'h5490
		10'd159: lut_data <= {8'h78 , 24'h548001};
		10'd160: lut_data <= {8'h78 , 24'h548108};
		10'd161: lut_data <= {8'h78 , 24'h548214};
		10'd162: lut_data <= {8'h78 , 24'h548328};
		10'd163: lut_data <= {8'h78 , 24'h548451};
		10'd164: lut_data <= {8'h78 , 24'h548565};
		10'd165: lut_data <= {8'h78 , 24'h548671};
		10'd166: lut_data <= {8'h78 , 24'h54877d};
		10'd167: lut_data <= {8'h78 , 24'h548887};
		10'd168: lut_data <= {8'h78 , 24'h548991};
		10'd169: lut_data <= {8'h78 , 24'h548a9a};
		10'd170: lut_data <= {8'h78 , 24'h548baa};
		10'd171: lut_data <= {8'h78 , 24'h548cb8};
		10'd172: lut_data <= {8'h78 , 24'h548dcd};
		10'd173: lut_data <= {8'h78 , 24'h548edd};
		10'd174: lut_data <= {8'h78 , 24'h548fea};
		10'd175: lut_data <= {8'h78 , 24'h54901d};
		//CMX(彩色矩阵控制) 16'h5381~16'h538b
		10'd176: lut_data <= {8'h78 , 24'h53811e};
		10'd177: lut_data <= {8'h78 , 24'h53825b};
		10'd178: lut_data <= {8'h78 , 24'h538308};
		10'd179: lut_data <= {8'h78 , 24'h53840a};
		10'd180: lut_data <= {8'h78 , 24'h53857e};
		10'd181: lut_data <= {8'h78 , 24'h538688};
		10'd182: lut_data <= {8'h78 , 24'h53877c};
		10'd183: lut_data <= {8'h78 , 24'h53886c};
		10'd184: lut_data <= {8'h78 , 24'h538910};
		10'd185: lut_data <= {8'h78 , 24'h538a01};
		10'd186: lut_data <= {8'h78 , 24'h538b98};
		//SDE(特殊数码效果)控制 16'h5580~16'h558b
		10'd187: lut_data <= {8'h78 , 24'h558006};
		10'd188: lut_data <= {8'h78 , 24'h558340};
		10'd189: lut_data <= {8'h78 , 24'h558410};
		10'd190: lut_data <= {8'h78 , 24'h558910};
		10'd191: lut_data <= {8'h78 , 24'h558a00};
		10'd192: lut_data <= {8'h78 , 24'h558bf8};
		10'd193: lut_data <= {8'h78 , 24'h501d40};//ISP MISC
		//CIP(颜色插值)控制 (16'h5300~16'h530c)
		10'd194: lut_data <= {8'h78 , 24'h530008};
		10'd195: lut_data <= {8'h78 , 24'h530130};
		10'd196: lut_data <= {8'h78 , 24'h530210};
		10'd197: lut_data <= {8'h78 , 24'h530300};
		10'd198: lut_data <= {8'h78 , 24'h530408};
		10'd199: lut_data <= {8'h78 , 24'h530530};
		10'd200: lut_data <= {8'h78 , 24'h530608};
		10'd201: lut_data <= {8'h78 , 24'h530716};
		10'd202: lut_data <= {8'h78 , 24'h530908};
		10'd203: lut_data <= {8'h78 , 24'h530a30};
		10'd204: lut_data <= {8'h78 , 24'h530b04};
		10'd205: lut_data <= {8'h78 , 24'h530c06};
		10'd206: lut_data <= {8'h78 , 24'h502500};
		//系统时钟分频 Bit[7:4]:系统时钟分频 input clock =24Mhz, PCLK = 48Mhz
		10'd207: lut_data <= {8'h78 , 24'h300802}; //正常工作模式
		10'd208: lut_data <= {8'h78 , 24'h303511};
		10'd209: lut_data <= {8'h78 , 24'h303646}; //PLL倍频
		10'd210: lut_data <= {8'h78 , 24'h3c0708};
		//时序控制 16'h3800~16'h3821
		10'd211: lut_data <= {8'h78 , 24'h382047};
		10'd212: lut_data <= {8'h78 , 24'h382100};
		10'd213: lut_data <= {8'h78 , 24'h381431};
		10'd214: lut_data <= {8'h78 , 24'h381531};
		10'd215: lut_data <= {8'h78 , 24'h380000};
		10'd216: lut_data <= {8'h78 , 24'h380100};
		10'd217: lut_data <= {8'h78 , 24'h380200};
		10'd218: lut_data <= {8'h78 , 24'h380304};
		10'd219: lut_data <= {8'h78 , 24'h38040a};
		10'd220: lut_data <= {8'h78 , 24'h38053f};
		10'd221: lut_data <= {8'h78 , 24'h380607};
		10'd222: lut_data <= {8'h78 , 24'h38079b};
		//设置输出像素个数
		10'd223: lut_data <= {8'h78 , 24'h380802}; //DVP 输出水平像素点数低4位 640
		10'd224: lut_data <= {8'h78 , 24'h380980}; //DVP 输出垂直像素点数高8位
		10'd225: lut_data <= {8'h78 , 24'h380a01}; //DVP 输出垂直像素点数低3位 480
		10'd226: lut_data <= {8'h78 , 24'h380be0}; //DVP 输出垂直像素点数低8位 
		10'd227: lut_data <= {8'h78 , 24'h380c07}; //水平总像素大小高5位 1896
		10'd228: lut_data <= {8'h78 , 24'h380d68}; //水平总像素大小低8位 
		10'd229: lut_data <= {8'h78 , 24'h380e03}; //垂直总像素大小高5位 984
		10'd230: lut_data <= {8'h78 , 24'h380fd8}; //垂直总像素大小低8位 
		10'd231: lut_data <= {8'h78 , 24'h381306};
		10'd232: lut_data <= {8'h78 , 24'h361800};
		10'd233: lut_data <= {8'h78 , 24'h361229};
		10'd234: lut_data <= {8'h78 , 24'h370952};
		10'd235: lut_data <= {8'h78 , 24'h370c03};
		10'd236: lut_data <= {8'h78 , 24'h3a0217};//60Hz max exposure
		10'd237: lut_data <= {8'h78 , 24'h3a0310};//60Hz max exposure
		10'd238: lut_data <= {8'h78 , 24'h3a1417};//50Hz max exposure
		10'd239: lut_data <= {8'h78 , 24'h3a1510};//50Hz max exposure
		10'd240: lut_data <= {8'h78 , 24'h400402};//BLC(背光) 2 lines
		10'd241: lut_data <= {8'h78 , 24'h30021c};//reset JFIFO, SFIFO, JPEG
		10'd242: lut_data <= {8'h78 , 24'h3006c3};//disable clock of JPEG2x, JPEG
		10'd243: lut_data <= {8'h78 , 24'h471303};//JPEG mode 3    
		10'd244: lut_data <= {8'h78 , 24'h440704};//量化标度
		10'd245: lut_data <= {8'h78 , 24'h460b35};
		10'd246: lut_data <= {8'h78 , 24'h460c22};
		10'd247: lut_data <= {8'h78 , 24'h483722};//DVP CLK divider
		10'd248: lut_data <= {8'h78 , 24'h382402};//DVP CLK divider
		10'd249: lut_data <= {8'h78 , 24'h5001a3};//SDE on, scale on, UV average off, color matrix on, AWB on
		10'd250: lut_data <= {8'h78 , 24'h350300};//AEC/AGC on
		//10'd251: lut_data <= {8'hff , 24'hffffff};
		//测试模式
		10'd251: lut_data <= {8'h78 , 24'h503d00}; //8'h00:正常模式 8'h80:彩条显示 8'h82:彩色四方形
		10'd252: lut_data <= {8'h78 , 24'h474100};
		10'd253: lut_data <= {8'hff , 24'hffffff};
	    //测试闪光灯功能
		//10'd253: lut_data <= {8'h78 , 24'h301602};
		//10'd254: lut_data <= {8'h78 , 24'h301c02};
		//10'd255: lut_data <= {8'h78 , 24'h301902}; //打开闪光灯
		//10'd256: lut_data <= {8'h78 , 24'h301900}; //关闭闪光灯	  
		//10'd257: lut_data <= {8'hff , 24'hffffff};
		default:lut_data  <= {8'h00 , 24'h000000};
	endcase
end

endmodule

 
