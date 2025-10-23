`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2025 11:06:35
// Design Name: 
// Module Name: testbench
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


`timescale 1ns/1ps
module MULT_TB;
  parameter A_WIDTH = 6;
  parameter B_WIDTH = 6;
  parameter P_WIDTH = A_WIDTH + B_WIDTH;
  
  //Input
  reg clk, rst_n, load;
  reg [A_WIDTH-1:0] A;
  reg [B_WIDTH-1:0] B;
  reg check_enable;

  wire [P_WIDTH-1:0] P_sim;
  wire [P_WIDTH-1:0] P_ref;
  
  wire two_model_out_equal;

  assign P_ref = $signed(A) * $signed(B);
  
  assign two_model_out_equal = (P_sim == P_ref);

  booth_mult #(.A_WIDTH(A_WIDTH), .B_WIDTH(B_WIDTH), .P_WIDTH(P_WIDTH)) booth_mult_inst (.clk(clk), .rst_n(rst_n), .load(load), .A(A), .B(B), .P(P_sim));
  
  initial begin
    clk = 1'b1;  // Initialize the clock to 1 (high)
  end

  // Always block to toggle the clock signal with the specified period
  always begin
    #5 clk = ~clk;  // Toggle clock every SYS_CLK_HALF_PERIOD time units
  end
  
  initial begin
    rst_n = 1; load = 0; check_enable = 0;
    #5; rst_n = 0; check_enable = 1;
    #20; rst_n = 1;
    
    repeat (1) begin
      @(negedge clk);
      A = 15; B = 9; load = 1;
      @(negedge clk);
      load = 0;
      repeat (B_WIDTH/2) @(negedge clk);
	  if (!two_model_out_equal) $display ("Test Failed, A = %b, B = %b", A, B);
      #300;
    end
    
    repeat (39) begin
      @(negedge clk);
      A = $urandom_range(1,2000); B = $urandom_range(1,128); load = 1;
      @(negedge clk);
      load = 0;
      repeat (B_WIDTH/2) @(negedge clk);
      if (!two_model_out_equal) $display ("Test Failed, A = %b, B = %b", A, B);
      #300;
    end
    
    #10;
    $stop;
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end

endmodule

