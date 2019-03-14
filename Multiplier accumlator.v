module multap(input [7:0]in_a,input [7:0]in_b,output reg [15:0]m_out);
always@(in_a,in_b)
begin
m_out<=in_a*in_b;
end
endmodule
module mult_acc(input [7:0]ina,input [7:0]inb,input aclr,input clk,output reg[15:0]out);
wire[15:0] multa_out,adder_out;
initial
begin
out<=16'h0000;
end
assign adder_out=multa_out+out;
always@(posedge clk,posedge aclr)
begin
if(aclr)out<=16'h0000;
else out<=adder_out;
end
multap add(ina,inb,multa_out);
endmodule
