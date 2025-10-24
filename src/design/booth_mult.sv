`timescale 1ns / 1ps
module booth_mult #(
  parameter A_WIDTH = 6,
  parameter B_WIDTH = 6,
  parameter P_WIDTH = A_WIDTH + B_WIDTH + 1
)(
  input  clk,
  input  rst_n,
  input  load,
  input  signed [A_WIDTH-1:0] A,
  input  signed [B_WIDTH-1:0] B,
  output reg signed [P_WIDTH-1:0] P
);

  // ==============================
  // Thanh ghi 
  // ==============================
  reg  signed [P_WIDTH+B_WIDTH:0] reg_PB;
  reg  signed [P_WIDTH+B_WIDTH:0] mid_PB;   
  reg  signed [P_WIDTH+B_WIDTH:0] next_PB; 

  // Booth control signals
  wire signed [2:0] booth_in;
  wire booth_enc_neg, booth_enc_A, booth_enc_2A;

  // X? lý s? A
  wire signed [P_WIDTH:0] A_ext;
  wire signed [P_WIDTH:0] A_shifted;
  wire signed [P_WIDTH:0] A_sel;
  wire signed [P_WIDTH:0] addsub_out;

  
  integer count;
  localparam MAX_COUNT = (B_WIDTH + 2)/ 2;
  reg done;


  typedef enum reg [1:0] {
    IDLE = 2'b00,
    SHIFT1 = 2'b01,
    ADD_SUB = 2'b10,
    SHIFT2 = 2'b11
  } state_t;

  state_t state;

  // ==============================
  // BOOTH ENCODER
  // ==============================
  assign booth_in = reg_PB[2:0]; // nhóm 3 bit th?p sau khi d?ch l?n 1

  booth_encoder u_booth_encoder (
    .booth_enc_in (booth_in),
    .booth_enc_neg(booth_enc_neg),
    .booth_enc_A  (booth_enc_A),
    .booth_enc_2A (booth_enc_2A)
  );

  assign A_ext     = {{(P_WIDTH+1-A_WIDTH){A[A_WIDTH-1]}}, A};
  assign A_shifted = A_ext <<<1;
  
  assign A_sel =
      booth_enc_2A ? A_shifted :
      booth_enc_A  ? A_ext :
                     { (P_WIDTH+1){1'b0} };

  // ==============================
  // ADD / SUB UNIT
  // ==============================
  add_sub_unit #(.WIDTH(P_WIDTH+1)) u_add_sub (
    .A   (mid_PB[P_WIDTH+B_WIDTH : B_WIDTH]), // ph?n P cao sau khi d?ch 1 l?n
    .B   (A_sel),
    .SnA (booth_enc_neg),
    .S   (addsub_out)
  );

  // ==============================
  // SEQUENTIAL LOGIC
  // ==============================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_PB <= 0;
      P      <= 0;
      count  <= 0;
      done   <= 1'b0;
      state  <= IDLE;
    end
    else begin
      case (state)
        IDLE: begin
          if (load) begin
            reg_PB <= { {(P_WIDTH+1){1'b0}}, B, 1'b0 }; // [P=0 | B | 0]
            P      <= 0;
            count  <= 0;
            done   <= 1'b0;
            state  <= SHIFT1;
          end
        end

        SHIFT1: begin
          // ======== D?ch 1 bit tr??c khi c?ng ========
          mid_PB <= $signed(reg_PB) >>> 1;
          state  <= ADD_SUB;
        end

        ADD_SUB: begin
          // ======== C?ng/tr? theo Booth encoder ========
          next_PB <= { addsub_out, mid_PB[B_WIDTH-1:0] };
          state   <= SHIFT2;
        end

        SHIFT2: begin
          // ======== D?ch ph?i thêm 1 bit (t?ng c?ng 2 bit m?i vòng) ========
          reg_PB <= $signed(next_PB) >>> 1;
          count  <= count + 1;

          // ======== L?u t?m k?t qu? ph?n P ========
          P <= mid_PB[P_WIDTH-1:0];

          if (count == MAX_COUNT - 1) begin
            done  <= 1'b1;
            state <= IDLE;
          end else begin
            state <= SHIFT1; // quay l?i chu k? ti?p theo
          end
        end
      endcase
    end
  end

endmodule

