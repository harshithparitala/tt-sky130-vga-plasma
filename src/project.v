/*
 * Copyright (c) 2026 Paritala Venkata Sai Harshith
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_harshith_vga_demo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs (VGA Pins)
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock (25.175 MHz standard VGA)
    input  wire       rst_n     // reset_n - active low
);

    // Disable bidirectional pins
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // VGA Standard 640x480 Timing Registers
    reg [9:0] h_count;
    reg [9:0] v_count;
    reg [5:0] frame_tick; // Controls movement speed

    // Standard VESA 640x480 @ 60Hz parameters
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_TOTAL   = 525;

    // Sync state machine counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 0;
            v_count <= 0;
            frame_tick <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                    frame_tick <= frame_tick + 1; // Update animation state
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Direct structural signals
    wire video_active = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    wire h_sync = ~((h_count >= (H_VISIBLE + H_FRONT)) && (h_count < (H_VISIBLE + H_FRONT + H_SYNC)));
    wire v_sync = ~((v_count >= (V_VISIBLE + V_FRONT)) && (v_count < (V_VISIBLE + V_FRONT + V_SYNC)));

    // Mathematical pattern matrix generation (Races the beam to save area)
    // Combines coordinate bit-shifting and XOR gates to draw complex interference patterns
    wire [1:0] plasma_red   = (h_count[5:4] ^ v_count[5:4]) + frame_tick[4:3];
    wire [1:0] plasma_green = (h_count[6:5] + frame_tick[5:4]) ^ v_count[6:5];
    wire [1:0] plasma_blue  = ~(h_count[4:3] ^ v_count[5:4]) - frame_tick[3:2];

    // Map outputs exactly to the TinyVGA Pmod specification
    // uo_out pinouts: [7]=HSYNC, [6]=B0, [5]=G0, [4]=R0, [3]=VSYNC, [2]=B1, [1]=G1, [0]=R1
    assign uo_out[0] = video_active ? plasma_red[1]   : 1'b0; // Red MSB
    assign uo_out[1] = video_active ? plasma_green[1] : 1'b0; // Green MSB
    assign uo_out[2] = video_active ? plasma_blue[1]  : 1'b0; // Blue MSB
    assign uo_out[3] = v_sync;                                // Vertical Sync
    assign uo_out[4] = video_active ? plasma_red[0]   : 1'b0; // Red LSB
    assign uo_out[5] = video_active ? plasma_green[0] : 1'b0; // Green LSB
    assign uo_out[6] = video_active ? plasma_blue[0]  : 1'b0; // Blue LSB
    assign uo_out[7] = h_sync;                                // Horizontal Sync

    // Explicitly group unused inputs to prevent toolchain compiler warnings
    wire _unused = &{ui_in, uio_in, ena, 1'b0};

endmodule
