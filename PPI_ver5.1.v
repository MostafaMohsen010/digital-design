`timescale 1us / 1us

//---------------------------Port Modules---------------------------//
module EightBitPort(D , DIntO, DIntI , mode ,enable);
inout  [7:0] D; 		//Data External
input  [7:0] DIntI;	//Data Internal input
output [7:0] DIntO;	//Data Internal output

//internal means between the port and the data bus
//external means between the port and the outside module (Top Module)

reg [7:0] DTemp;

input enable;
input mode; //Low(read/Input): DInt = D , High(write/Output): D = Dint

assign D = (mode)? DTemp:8'bz;	   //if mode is Low(read/Input) , then D is high impedance otherwise = DTemp
assign DIntO = mode? 8'bz:D;  //if mode is High(write/Output) , then DIntO is high impedance for input otherwise = D


always @(enable ,mode ,DIntI)
begin
	if (mode == 1 & enable) DTemp <= DIntI;//value of Dtemp only changes when the enable signal is high
	
end
endmodule

module FourBitPort(D , DIntO, DIntI , mode ,enable);
inout [3:0] D; 		//Data External
input [3:0] DIntI;	//Data Internal input
output [3:0] DIntO;	//Data Internal output

//internal means between the port and the data bus
//external means between the port and the outside module (Top Module)

reg [3:0] DTemp;

input enable;
input mode; //Low(read/Input): DInt = D , High(write/Output): D = Dint

assign D = (mode)? DTemp:4'bz;	   //if mode is Low(read/Input) , then D is high impedance otherwise = DTemp
assign DIntO = mode? 4'bz:D;  //if mode is High(write/Output) , then DIntO is high impedance for input otherwise = D


always @(enable ,mode ,DIntI)
begin
	if (mode == 1 & enable) DTemp = DIntI;//value of Dtemp only changes when the enable signal is high
end
endmodule

module PortC(C_Inout ,CInt_In ,CInt_Out, mode ,enable ,BSR ,BSRBitAddr ,BSRValue);
inout  [7:0] C_Inout;  //C inout
input  [7:0] CInt_In; 	 //C Internal Input
output [7:0] CInt_Out;	 //C Internal output

input [1:0] mode;
input enable ,BSR ,BSRValue; //the enable signal , and the BSR mode enable signal and the bit's value
input [2:0] BSRBitAddr; 

reg [7:0] CInt_In_Intermediate;//assigned in always block to CInt_In when BSR off ,but changed when BSR is on



always @(BSR , CInt_Out ,CInt_In,BSRValue ,BSRBitAddr)
begin
//BSR mode handling

//if BSR is on , then we will overwrite inner CInt by the reg overWrittenCInt
	if (BSR)
	begin
		CInt_In_Intermediate <= CInt_Out;
		CInt_In_Intermediate[BSRBitAddr] <= BSRValue;
	end
	if (!BSR) CInt_In_Intermediate <= CInt_In;
	
end

FourBitPort portCLower(C_Inout[3:0] , CInt_Out[3:0], CInt_In_Intermediate[3:0] , mode[0] ,enable|BSR);
FourBitPort portCUpper(C_Inout[7:4] , CInt_Out[7:4], CInt_In_Intermediate[7:4] , mode[1] ,enable|BSR);
endmodule

module InputInterface(DataMode ,enable , SelectPorts , WR , RD , A , reset , CS);
output [3:0]SelectPorts;
output DataMode;
output enable;

input WR , RD , reset , CS;
input [1:0]A;

assign enable = CS && (WR ^ RD); //enable is high if CS is high and only one signal (read or write) is high

//A0A1 is one hot encoded into SlectPorts wires
assign SelectPorts[0] = A==0?1:0;
assign SelectPorts[1] = A==1?1:0;
assign SelectPorts[2] = A==2?1:0;
assign SelectPorts[3] = A==3?1:0;

//DataMode is set to input at reset
assign DataMode = reset?0:!WR&RD?1:0;
endmodule

module Control(modes ,BSR ,BSRBitAddr ,BSRValue, enable ,reset ,inCtrlWord);
output reg [3:0]modes;
output reg BSR , BSRValue;   //BSR enable signal and the value of the BSR bit
output reg [2:0] BSRBitAddr; //Address of the BSR bit to be written in Port c

input [7:0] inCtrlWord;
input enable ,reset; //the enable signal is from the Input Interface module the reset from the top module

//The actual control word
reg [7:0]ctrlWord ;

initial
begin
	ctrlWord <= 8'b0111_1111;
end

//---------------------------Controlling---------------------------//
always @(enable , reset , inCtrlWord ,BSR ,BSRBitAddr,BSRValue ,modes ,ctrlWord)
begin
	if (!reset && enable) ctrlWord <= inCtrlWord;//when enable signal is high, write the ctrlWord
	if (reset) ctrlWord <= 8'b0111_1111;//when reset signal is high ,ctrlWord is forced to 8'b0111_1111 to set all ports to input mode 
	
	//---------------------------Modes Handling---------------------------//
	if (ctrlWord[7] == 1) //then BSR Mode
	begin
		BSR = 1; 		 	//enable BSR mode
		BSRValue = ctrlWord[0];	 	//assign the BSR bit value
		BSRBitAddr = ctrlWord[3:1];	//assign the address of the BSR bit
		modes[2] = 1;			//change lower c port to output
		modes[3] = 1; 			//change upper c port to output
	end
	else if(ctrlWord[7] == 0) //then mode 0
	begin
		BSR = 0;//disable BSR mode
		//Port A mode handling
		if (ctrlWord[4])  modes[0] = 0;
		if (!ctrlWord[4]) modes[0] = 1;

		//Port B mode handling
		if (ctrlWord[1])  modes[1] = 0;
		if (!ctrlWord[1]) modes[1] = 1;

		//Port C lower mode handling
		if (ctrlWord[0])  modes[2] = 0;
		if (!ctrlWord[0]) modes[2] = 1;

		//Port C upper mode handling
		if (ctrlWord[3])  modes[3] = 0;
		if (!ctrlWord[3]) modes[3] = 1;
	end
end
endmodule

module PPI_8255_ver2(A_Inout , B_Inout , C_Inout , D_Inout ,WR ,RD ,CS ,reset ,portAddr);

inout [7:0] A_Inout;
inout [7:0] B_Inout;
inout [7:0] C_Inout;
inout [7:0] D_Inout;
input WR ,RD ,CS ,reset;
input [1:0] portAddr;

wire [7:0] AInt_In;
wire [7:0] AInt_Out;

wire [7:0] BInt_In;
wire [7:0] BInt_Out;

wire [7:0] CInt_In;
wire [7:0] CInt_Out;

wire [7:0] DInt_In;
wire [7:0] DInt_Out;

wire enable, enableA ,enableB ,enableC ,enableCtrl; //enable signals for each port individually
wire DataMode;
wire BSR , BSRValue;
wire [2:0] BSRBitAddr;
wire [7:0] InCtrlWord;

wire [3:0] modes;//the input or output mode for each port .0 = input and 1 = output
wire [3:0] SelectPorts;//one hot encoded A0 A1

reg [7:0] mainBus;

//for a enable signal to be high ,we need to make sure that the port is selected by A0 A1
assign enableA = enable & SelectPorts[0];
assign enableB = enable & SelectPorts[1];
assign enableC = enable & SelectPorts[2];
assign enableCtrl = enable & SelectPorts[3];

//assign the main bus to all internal input wires
assign AInt_In    = mainBus;
assign BInt_In    = mainBus;
assign CInt_In    = mainBus;
assign DInt_In    = mainBus;

assign InCtrlWord = mainBus;

always @ (DataMode ,SelectPorts , AInt_Out ,BInt_Out,CInt_Out,DInt_Out)
begin
//assign the selected port - by A0A1 - to the main bus
	if (DataMode) //if the cpu is trying to read data from ports
	begin
		if (SelectPorts[0]) mainBus <= AInt_Out; //if port A was selected
		if (SelectPorts[1]) mainBus <= BInt_Out; //if port B was selected
		if (SelectPorts[2]) mainBus <= CInt_Out; //if port C was selected
	end
	
	if (!DataMode) mainBus <= DInt_Out; //if cpu is trying to write data to ports
	
	//Note: if DataMode is low -reading ports- and the selected port was output mode and not input
	//the value of the output of it would be high impedance 
	//e.g AInt_Out = zzzz_zzzz therfore mainBus = zzzz_zzzz therfore DInt_In = zzzz_zzzz
end 

EightBitPort dataBuffer(D_Inout , DInt_Out ,DInt_In , DataMode ,enable);
EightBitPort portA(A_Inout , AInt_Out ,AInt_In , modes[0] ,enableA);
EightBitPort portB(B_Inout , BInt_Out ,BInt_In , modes[1] ,enableB);
PortC portC(C_Inout ,CInt_In ,CInt_Out, modes[3:2] ,enableC ,BSR ,BSRBitAddr ,BSRValue);
InputInterface inputInterface(DataMode ,enable , SelectPorts , WR , RD , portAddr , reset , CS);
Control control(modes ,BSR ,BSRBitAddr ,BSRValue, enableCtrl ,reset ,InCtrlWord);
endmodule

module tb_PPI_WaveForm();

wire [7:0] portA;
wire [7:0] portB;
wire [7:0] portC;
wire [7:0] portD;
wire WR ,RD ,CS ,reset;
wire [1:0] A;

initial
begin
	$monitor(" A=%b,B=%b, C=%b ,D=%b ,wr=%b ,rd=%b, cs=%b ,RESET=%b",portA,portB,portC,portD,WR,RD,CS,reset );
end

PPI_8255_ver2 ppi(portA , portB , portC , portD ,!WR ,!RD ,!CS ,reset ,A);
endmodule

module tb_PPI();		//note run simulation in 230us step

wire [7:0] portA;
wire [7:0] portB;
wire [7:0] portC;
wire [7:0] portD;

reg [7:0] portAReg;
reg [7:0] portBReg;
reg [7:0] portCReg;
reg [7:0] portDReg;

reg [4:0]modes;

assign portA = modes[0]?8'bz:portAReg;
assign portB = modes[1]?8'bz:portBReg;
assign portC[3:0] = modes[2]?4'bz:portCReg[3:0];
assign portC[7:4] = modes[3]?4'bz:portCReg[7:4];
assign portD = modes[4]?8'bz:portDReg;

reg WR ,RD ,CS ,reset;
reg [1:0] A;

initial
begin

	$monitor(" A=%b,B=%b, C=%b ,D=%b ,wr=%b ,rd=%b, cs=%b ,RESET=%b",portA,portB,portC,portD,WR,RD,CS,reset );

	reset =1;
	CS =0;
	RD	=1;
	WR	=1;
	#10
	reset=0;
	modes[4] = 5'b00000;
	
	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------A = input-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0001_0000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0001_0000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 1;modes[0] = 0;
	portAReg = 8'b1000_0001;
	A=2'b00;
	#10 RD = 0; #10
	#10;$display("D Read from A 1000_0001");

	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------A = output-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 0;modes[0] = 1;
	portDReg = 8'b0001_1000;
	A=2'b00;
	#10 WR = 0; #10
	#10;$display("D wrote to A 0001_1000");
	
	#10;WR=1;RD=1;#10
	
	
	#10$display("//-------------------B = input-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0010;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0010");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 1;modes[1] = 0;
	portAReg = 8'b1100_0011;
	A=2'b01;
	#10 RD = 0; #10
	#10;$display("D Read from B 1100_0011");

	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------B = output-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 0;modes[1] = 1;
	portDReg = 8'b0011_1100;
	A=2'b01;
	#10 WR = 0; #10
	#10;$display("D wrote to B 0011_1100");
	
	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------C lower = input-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0001;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0001");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 1;modes[2] = 0;
	portCReg = 8'b1010_1101;
	A=2'b10;
	#10 RD = 0; #10
	#10;$display("D Read from C lower zzzz_1101");

	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------C lower = output-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 0;modes[2] = 1;
	portDReg = 8'b1101_1010;
	A=2'b10;
	#10 WR = 0; #10
	#10;$display("D wrote to C lower zzzz_1010");//1101_1010 not zzzz_1010
	
	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------C upper = input-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_1000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_1000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 1;modes[3] = 0;
	portCReg = 8'b1010_1101;
	A=2'b10;
	#10 RD = 0; #10
	#10;$display("D Read from C upper 1010_zzzz");

	#10;WR=1;RD=1;#10
	
	#10$display("//-------------------C upper = output-------------------//");
	modes[4] = 0;
	A 	=2'b11;
	portDReg = 8'b0000_0000;
	#10 WR = 0; #10
	#10;$display("CWR Written 0000_0000");
	
	#10;WR=1;RD=1;#10
	
	modes[4] = 0;modes[3] = 1;
	portDReg = 8'b0100_1111;
	A=2'b10;
	#10 WR = 0; #10
	#10;$display("D wrote to C upper 0100_zzzz");
	
end

PPI_8255_ver2 ppi(portA , portB , portC , portD ,!WR ,!RD ,!CS ,reset ,A);

endmodule
