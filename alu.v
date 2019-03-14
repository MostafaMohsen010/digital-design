module sll(input [7:0]in_a,input reg [7:0]in_b,output reg [15:0]out);
reg [2:0]conc_no;
always
begin
for(conc_no=0;conc_no<in_b;conc_no=conc_no+1)   //making no of concatinations for in_a = value of in_b
output<={in_a,1'b0};                               // same as in_a*pow(2,inb)
//if(conc_no==1'b1)conc_no<=in_b;                         
end
endmodule
module Alu(input [7:0]in_1,input [7:0]in_2,output reg [15:0]alu_out,input [2:0]func,input enable,input aclr,output reg zero_flag,output reg overflow);
always@(*)
begin
if(aclr)alu_out<=16'h0000;
else if(enable)
begin
case(func)
3'b000:alu_out<=in_1+in_2;    //bitwise addition
3'b001:alu_out<=in_1*in_2;    //bitwise multiplication
3'b010:alu_out<=in_1&in_2;    //bitwise and  see and_gate project to solve these problems
3'b011:alu_out<=in_1|in_2;    //bitwise or
3'b100:alu_out<=in_1^in_2;    //bitwise xor
3'b101:alu_out<=in_1<in_2?1:0; //compare the two inputs 
3'b110:
endcase
end
if(alu_out==16'h0000)zero_flag=1'b1;
else zero_flag=1'b0;
if(alu_out==16'hffff)overflow=1'b1;
else overflow=1'b0;
end
endmodule
