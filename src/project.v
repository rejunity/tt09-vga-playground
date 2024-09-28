/*
 * Copyright (c) 2024 Renaldas Zioma
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_rejunity_vga_playground(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] x;
  wire [9:0] y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  
  wire out[255:0];
  wire [5:0] out_;
  wire [10:0] ccc = counter[4:0];
  // wire [1:0] out_ = out[0] + out[1] + out[2] + out[3] + out[4] + out[5] + out[6];
	genvar i;
  generate
  // always @(*) begin
    for (i = 0; i < 64; i = i + 2) begin
      integer d = (256 - i);
      //wire [3:0] d = 12 - i[6:3];                  
      // assign out[i] = ~|((x[8:0] - (y>>1) + counter*i) & y);
      wire  [9:0] x_ = ((x+ ((ccc*(i+32))>>3) )*d)>>7;// x + ((counter*(i)) >> d);//(x[8:0] - (y>>1) + ((counter*(i)) >> 5));
      wire  [9:0] y_ = ((y+ ((ccc*i)>>3) )*d)>>7;//y + ((counter*(i)) >> d);
      // wire signed [8:0] x_ = (((x)-256)*d)>>7;//((x+((ccc*i)>>3) )*d)>>7;// x + ((counter*(i)) >> d);//(x[8:0] - (y>>1) + ((counter*(i)) >> 5));
      // wire [8:0] y_ = ((y-256)*d)>>7;//((y+((ccc*i)>>3) )*d)>>7;//y + ((counter*(i)) >> d);
    
      wire [8:0] z_ = i;

      assign out[i] = (~|(y_[8:0] & (i*8))) & (x_[7:5] == 0);
                      // | (y_[6] & (x_[6] ^ z_[5]) & (y_[6] ^ z_[3]) & (x_[7] ^ y_[7]));
      // assign out[i] = (x_[6] ^ z_[5]) & (y_[6] ^ z_[4]) & (x_[7] ^ y_[7]); //(z_[3] & (x_[5] ^ y_[5])) & (x_[7] ^ y_[7]);
      // assign out[i] = ~|(x_ & (i[7:0]&y[8:0]));// & y);
      // if (i == 0)
      //   assign out_ = out[0];
      // else
      //   assign out_ = out_ + out[i];
      // assign out_ = (i == 0 ? 0 : out_) + out[i];
      // assign out_ = out[i] && (out_ == 0) ? i : 0;// (i == 0 ? 0 : out_) + out[i];
      if (i == 0)
        assign out_ = out[i];
      else
        assign out_ = out[i] ? i: out_;
    end
  // end
  endgenerate

  // out[i] = i[1:0];//x[8:0] - (y>>1) + counter*i;

  //  H = ( X'' | D ) & Y' 
  // wire [8:0] x_ = x[8:0] - (y>>1) + counter*10;
  // wire [8:0] x__ = x[8:0] - (y>>1) + counter*11;
  // wire [8:0] x___ = x[8:0] - (y>>1) + counter*12;
  // wire [8:0] x____ = x[8:0] - (y>>1) + counter*13;
  // wire [8:0] x_____ = x[8:0] - (y>>1) + counter*14;
  // wire [8:0] x______ = x[8:0] - (y>>1) + counter*15;
  wire [8:0] y_ = y[8:0];
  // wire [1:0] out = ~|(x_ & y_)
  //       + ~|(x__ & y_)
  //       + ~|(x___ & y_)
  //       + ~|(x____ & y_)
  //       + ~|(x_____ & y_)
  //       + ~|(x______ & y_);

  // wire [1:0] out = ~|(x_ & y_ & 252);
  // wire [1:0] out = &(x_ | y_);
  // wire [1:0] out = &(x_ | y_);

  assign {R,G,B} = video_active * out_;//{3{out_}};

  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  
endmodule
