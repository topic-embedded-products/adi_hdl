// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// Each core or library found in this collection may have its own licensing terms. 
// The user should keep this in in mind while exploring these cores. 
//
// Redistribution and use in source and binary forms,
// with or without modification of this file, are permitted under the terms of either
//  (at the option of the user):
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory, or at:
// https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
//
// OR
//
//   2.  An ADI specific BSD license as noted in the top level directory, or on-line at:
// https://github.com/analogdevicesinc/hdl/blob/dev/LICENSE
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_dac_jesd204_channel #(
  parameter CHANNEL_ID = 0,
  parameter DATAPATH_DISABLE = 0,
  parameter DATA_PATH_WIDTH = 4
) (
  // dac interface

  input                                 dac_clk,
  input                                 dac_rst,
  output reg                            dac_enable,
  output reg  [DATA_PATH_WIDTH*16-1:0]  dac_data,
  input       [DATA_PATH_WIDTH*16-1:0]  dma_data,

  // processor interface

  input                                 dac_data_sync,
  input                                 dac_dds_format,

  // bus interface

  input                                 up_clk,
  input                                 up_rstn,
  input                                 up_wreq,
  input       [13:0]                    up_waddr,
  input       [31:0]                    up_wdata,
  output                                up_wack,
  input                                 up_rreq,
  input       [13:0]                    up_raddr,
  output      [31:0]                    up_rdata,
  output                                up_rack
);

  localparam DW = DATA_PATH_WIDTH * 16 - 1;

  // internal registers

  reg     [DW:0]  dac_pn7_data = 'd0;
  reg     [DW:0]  dac_pn15_data = 'd0;
  reg     [15:0]  dac_dds_phase_0[0:DATA_PATH_WIDTH-1];
  reg     [15:0]  dac_dds_phase_1[0:DATA_PATH_WIDTH-1];
  reg     [15:0]  dac_dds_incr_0 = 'd0;
  reg     [15:0]  dac_dds_incr_1 = 'd0;
  reg     [DW:0]  dac_dds_data = 'd0;

  // internal signals

  wire    [DW:0]  dac_dds_data_s;
  wire    [15:0]  dac_dds_scale_1_s;
  wire    [15:0]  dac_dds_init_1_s;
  wire    [15:0]  dac_dds_incr_1_s;
  wire    [15:0]  dac_dds_scale_2_s;
  wire    [15:0]  dac_dds_init_2_s;
  wire    [15:0]  dac_dds_incr_2_s;
  wire    [15:0]  dac_pat_data_1_s;
  wire    [15:0]  dac_pat_data_2_s;
  wire    [ 3:0]  dac_data_sel_s;

  wire    [DW:0]    pn15;
  wire    [DW+15:0] pn15_full_state;
  wire    [DW:0]    dac_pn15_data_s;
  wire    [DW:0]    pn7;
  wire    [DW+7:0]  pn7_full_state;
  wire    [DW:0]    dac_pn7_data_s;

  // PN15 x^15 + x^14 + 1
  assign pn15 = pn15_full_state[15+:DW+1] ^ pn15_full_state[14+:DW+1];
  assign pn15_full_state = {dac_pn15_data[14:0],pn15};

  // PN7 x^7 + x^6 + 1
  assign pn7 = pn7_full_state[7+:DW+1] ^ pn7_full_state[6+:DW+1];
  assign pn7_full_state = {dac_pn7_data[6:0],pn7};

  generate
  genvar i;
  for (i = 0; i < DATA_PATH_WIDTH; i = i + 1) begin: g_pn_swizzle
    localparam src_lsb = i * 16;
    localparam dst_lsb = (DATA_PATH_WIDTH - i - 1) * 16;

    assign dac_pn15_data_s[dst_lsb+:16] = dac_pn15_data[src_lsb+:16];
    assign dac_pn7_data_s[dst_lsb+:16] = dac_pn7_data[src_lsb+:16];
  end
  endgenerate

  // dac data select

  always @(posedge dac_clk) begin
    dac_enable <= (dac_data_sel_s == 4'h2) ? 1'b1 : 1'b0;
    case (dac_data_sel_s)
      4'h7: dac_data <= dac_pn15_data_s;
      4'h6: dac_data <= dac_pn7_data_s;
      4'h5: dac_data <= ~dac_pn15_data_s;
      4'h4: dac_data <= ~dac_pn7_data_s;
      4'h3: dac_data <= 'h00;
      4'h2: dac_data <= dma_data;
      4'h1: dac_data <= {DATA_PATH_WIDTH/2{dac_pat_data_2_s, dac_pat_data_1_s}};
      default: dac_data <= dac_dds_data;
    endcase
  end

  // pn registers

  always @(posedge dac_clk) begin
    if (dac_data_sync == 1'b1) begin
      dac_pn15_data <= {DW+1{1'd1}};
      dac_pn7_data <= {DW+1{1'd1}};
    end else begin
      dac_pn15_data <= pn15;
      dac_pn7_data <= pn7;
    end
  end

  // dds

  generate
  if (DATAPATH_DISABLE == 1) begin
    always @(posedge dac_clk) begin
      dac_dds_data <= 64'd0;
    end
  end else begin
    genvar i;

    always @(posedge dac_clk) begin
      if (dac_data_sync == 1'b1) begin
        dac_dds_incr_0 <= dac_dds_incr_1_s * DATA_PATH_WIDTH;
        dac_dds_incr_1 <= dac_dds_incr_2_s * DATA_PATH_WIDTH;
        dac_dds_data <= 64'd0;
      end else begin
        dac_dds_incr_0 <= dac_dds_incr_0;
        dac_dds_incr_1 <= dac_dds_incr_1;
        dac_dds_data <= dac_dds_data_s;
      end
    end

    for (i = 0; i < DATA_PATH_WIDTH; i = i + 1) begin: g_dds_phase

      always @(posedge dac_clk) begin
        if (dac_data_sync == 1'b1) begin
          if (i == 0) begin
            dac_dds_phase_0[i] <= dac_dds_init_1_s;
            dac_dds_phase_1[i] <= dac_dds_init_2_s;
          end else begin
            dac_dds_phase_0[i] <= dac_dds_phase_0[i-1] + dac_dds_incr_1_s;
            dac_dds_phase_1[i] <= dac_dds_phase_1[i-1] + dac_dds_incr_2_s;
          end
        end else begin
          dac_dds_phase_0[i] <= dac_dds_phase_0[i] + dac_dds_incr_0;
          dac_dds_phase_1[i] <= dac_dds_phase_1[i] + dac_dds_incr_1;
        end
      end

      ad_dds i_dds (
        .clk (dac_clk),
        .dds_format (dac_dds_format),
        .dds_phase_0 (dac_dds_phase_0[i]),
        .dds_scale_0 (dac_dds_scale_1_s),
        .dds_phase_1 (dac_dds_phase_1[i]),
        .dds_scale_1 (dac_dds_scale_2_s),
        .dds_data (dac_dds_data_s[16*i+:16])
      );
    end
  end
  endgenerate

  // single channel processor

  up_dac_channel #(
    .CHANNEL_ID(CHANNEL_ID),
    .USERPORTS_DISABLE(1),
    .IQCORRECTION_DISABLE(1)
  ) i_up_dac_channel (
    .dac_clk (dac_clk),
    .dac_rst (dac_rst),
    .dac_dds_scale_1 (dac_dds_scale_1_s),
    .dac_dds_init_1 (dac_dds_init_1_s),
    .dac_dds_incr_1 (dac_dds_incr_1_s),
    .dac_dds_scale_2 (dac_dds_scale_2_s),
    .dac_dds_init_2 (dac_dds_init_2_s),
    .dac_dds_incr_2 (dac_dds_incr_2_s),
    .dac_pat_data_1 (dac_pat_data_1_s),
    .dac_pat_data_2 (dac_pat_data_2_s),
    .dac_data_sel (dac_data_sel_s),
    .dac_iq_mode (),
    .dac_iqcor_enb (),
    .dac_iqcor_coeff_1 (),
    .dac_iqcor_coeff_2 (),
    .up_usr_datatype_be (),
    .up_usr_datatype_signed (),
    .up_usr_datatype_shift (),
    .up_usr_datatype_total_bits (),
    .up_usr_datatype_bits (),
    .up_usr_interpolation_m (),
    .up_usr_interpolation_n (),
    .dac_usr_datatype_be (1'b0),
    .dac_usr_datatype_signed (1'b1),
    .dac_usr_datatype_shift (8'd0),
    .dac_usr_datatype_total_bits (8'd16),
    .dac_usr_datatype_bits (8'd16),
    .dac_usr_interpolation_m (16'd1),
    .dac_usr_interpolation_n (16'd1),

    .up_clk (up_clk),
    .up_rstn (up_rstn),
    .up_wreq (up_wreq),
    .up_waddr (up_waddr),
    .up_wdata (up_wdata),
    .up_wack (up_wack),
    .up_rreq (up_rreq),
    .up_raddr (up_raddr),
    .up_rdata (up_rdata),
    .up_rack (up_rack)
  );

endmodule
