// 4-bit adder
module add(
    input [3:0] a,b,
    output [4:0] y
    );
  
    assign y = a + b;  
  
endmodule
 
// Interface
interface add_if();
    logic [3:0] a;
    logic [3:0] b;
    logic [4:0] y;
endinterface