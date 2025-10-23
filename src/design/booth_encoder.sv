`timescale 1ns / 1ps
module booth_encoder (
  input  [2:0] booth_enc_in,
  output reg booth_enc_neg,
  output reg booth_enc_A,
  output reg booth_enc_2A
);

  always @(*) begin
  {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b000; // mặc định
  case (booth_enc_in)
    3'b000, 3'b111: {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b000;
    3'b001, 3'b010: {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b010;
    3'b011:         {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b001;
    3'b100:         {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b101;
    3'b101, 3'b110: {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b110;
    default:        {booth_enc_neg, booth_enc_A, booth_enc_2A} = 3'b000;
  endcase
end

endmodule

