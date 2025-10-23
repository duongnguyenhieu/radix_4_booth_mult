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
  // Thanh ghi chính chứa cả P và B
  // [P cao | B thấp | bit 0 bổ sung]
  // ==============================
  reg  signed [P_WIDTH+B_WIDTH:0] reg_PB;
  reg  signed [P_WIDTH+B_WIDTH:0] mid_PB;   // sau khi dịch lần 1
  reg  signed [P_WIDTH+B_WIDTH:0] next_PB;  // sau khi cộng/trừ

  // Booth control signals
  wire signed [2:0] booth_in;
  wire booth_enc_neg, booth_enc_A, booth_enc_2A;

  // Xử lý số A
  wire signed [P_WIDTH:0] A_ext;
  wire signed [P_WIDTH:0] A_shifted;
  wire signed [P_WIDTH:0] A_sel;
  wire signed [P_WIDTH:0] addsub_out;

  // Bộ đếm vòng lặp
  integer count;
  localparam MAX_COUNT = (B_WIDTH + 2)/ 2;
  reg done;

  // Trạng thái điều khiển FSM
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
  assign booth_in = mid_PB[2:0]; // nhóm 3 bit thấp sau khi dịch lần 1

  booth_encoder u_booth_encoder (
    .booth_enc_in (booth_in),
    .booth_enc_neg(booth_enc_neg),
    .booth_enc_A  (booth_enc_A),
    .booth_enc_2A (booth_enc_2A)
  );

  // ==============================
  // Mở rộng A sang độ rộng của P
  // ==============================
  assign A_ext     = {{(P_WIDTH+1-A_WIDTH){A[A_WIDTH-1]}}, A};
  assign A_shifted = A_ext <<<1;

  // Chọn hệ số nhân
  assign A_sel =
      booth_enc_2A ? A_shifted :
      booth_enc_A  ? A_ext :
                     { (P_WIDTH+1){1'b0} };

  // ==============================
  // ADD / SUB UNIT
  // ==============================
  add_sub_unit #(.WIDTH(P_WIDTH+1)) u_add_sub (
    .A   (mid_PB[P_WIDTH+B_WIDTH : B_WIDTH]), // phần P cao sau khi dịch 1 lần
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
          // ======== Dịch 1 bit trước khi cộng ========
          mid_PB <= $signed(reg_PB) >>> 1;
          state  <= ADD_SUB;
        end

        ADD_SUB: begin
          // ======== Cộng/trừ theo Booth encoder ========
          next_PB <= { addsub_out, mid_PB[B_WIDTH-1:0] };
          state   <= SHIFT2;
        end

        SHIFT2: begin
          // ======== Dịch phải thêm 1 bit (tổng cộng 2 bit mỗi vòng) ========
          reg_PB <= $signed(next_PB) >>> 1;
          count  <= count + 1;

          // ======== Lưu tạm kết quả phần P ========
          P <= reg_PB[P_WIDTH-1:0];

          if (count == MAX_COUNT - 1) begin
            done  <= 1'b1;
            state <= IDLE;
          end else begin
            state <= SHIFT1; // quay lại chu kỳ tiếp theo
          end
        end
      endcase
    end
  end

endmodule
