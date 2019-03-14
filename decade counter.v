/*module clk_gen #(parameter period=100)(output reg clk);
initial clk=1'b0;
always
#(period/2)clk=~clk;
initial #(500) $finish;
endmodule*/
module cntr #(parameter period=50)(input[7:0]load,input aclr,input [1:0]func,output reg[7:0]q,input set_max,input clk);
initial 
begin
//aclr=1'b0;
//set_max=1'b0;
//clk=1'b0;
end
//always 
//#(period/2)clk=~clk;
always@(posedge clk,posedge aclr,posedge set_max)
begin
if(aclr)q<=8'h00; 
else if(set_max) q<=8'hFF;
else case (func)
2'b00:q<=q+1;
2'b01:q<=q-1;
2'b10:q<=load;
endcase
end
initial #(700) $finish;
endmodule
