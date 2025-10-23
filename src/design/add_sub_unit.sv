module add_sub_unit #(parameter WIDTH = 8)(
  input  signed [WIDTH-1:0] A,
  input  signed [WIDTH-1:0] B,
  input  SnA, 
  output signed [WIDTH-1:0] S
);
  assign S = SnA ? (A - B) : (A + B);
endmodule
