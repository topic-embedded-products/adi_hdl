// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// This core  is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory of
//      the repository (LICENSE_GPL2), and at: <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license as noted in the top level directory, or on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  // clock and resets

  input             sys_clk,
  input             sys_resetn,

  // ddr3

  output            ddr3_clk_p,
  output            ddr3_clk_n,
  output  [ 14:0]   ddr3_a,
  output  [  2:0]   ddr3_ba,
  output            ddr3_cke,
  output            ddr3_cs_n,
  output            ddr3_odt,
  output            ddr3_reset_n,
  output            ddr3_we_n,
  output            ddr3_ras_n,
  output            ddr3_cas_n,
  inout   [  7:0]   ddr3_dqs_p,
  inout   [  7:0]   ddr3_dqs_n,
  inout   [ 63:0]   ddr3_dq,
  output  [  7:0]   ddr3_dm,
  input             ddr3_rzq,
  input             ddr3_ref_clk,

  // ethernet

  input             eth_ref_clk,
  input             eth_rxd,
  output            eth_txd,
  output            eth_mdc,
  inout             eth_mdio,
  output            eth_resetn,
  input             eth_intn,

  // board gpio

  input   [ 10:0]   gpio_bd_i,
  output  [ 15:0]   gpio_bd_o,

  // lane interface

  input             ref_clk0,
  input             ref_clk1,
  input   [  3:0]   rx_data,
  output  [  3:0]   tx_data,
  output            rx_sync,
  output            rx_os_sync,
  input             tx_sync,
  input             sysref,

  output            ad9528_reset_b,
  output            ad9528_sysref_req,
  output            ad9371_tx1_enable,
  output            ad9371_tx2_enable,
  output            ad9371_rx1_enable,
  output            ad9371_rx2_enable,
  output            ad9371_test,
  output            ad9371_reset_b,
  input             ad9371_gpint,

  inout   [ 18:0]   ad9371_gpio,

  output            spi_csn_ad9528,
  output            spi_csn_ad9371,
  output            spi_clk,
  output            spi_mosi,
  input             spi_miso);

  // internal signals

  wire              eth_reset;
  wire              eth_mdio_i;
  wire              eth_mdio_o;
  wire              eth_mdio_t;
  wire    [ 63:0]   gpio_i;
  wire    [ 63:0]   gpio_o;
  wire    [  7:0]   spi_csn_s;
  wire              dac_fifo_bypass;

  // assignments

  assign spi_csn_ad9528 = spi_csn_s[0];
  assign spi_csn_ad9371 = spi_csn_s[1];

  // gpio (ad9371)

  assign gpio_i[63:61] = gpio_o[63:61];

  assign dac_fifo_bypass = gpio_o[60];
  assign gpio_i[60:60] = gpio_o[60];

  assign ad9528_reset_b = gpio_o[59];
  assign ad9528_sysref_req = gpio_o[58];
  assign ad9371_tx1_enable = gpio_o[57];
  assign ad9371_tx2_enable = gpio_o[56];
  assign ad9371_rx1_enable = gpio_o[55];
  assign ad9371_rx2_enable = gpio_o[54];
  assign ad9371_test = gpio_o[53];
  assign ad9371_reset_b = gpio_o[52];
  assign gpio_i[59:52] = gpio_o[59:52];

  assign gpio_i[51:51] = ad9371_gpint;

  assign gpio_i[50:32] = gpio_o[50:32];

  // board stuff

  assign eth_resetn = ~eth_reset;
  assign eth_mdio_i = eth_mdio;
  assign eth_mdio = (eth_mdio_t == 1'b1) ? 1'bz : eth_mdio_o;

  assign ddr3_a[14:12] = 3'd0;

  assign gpio_i[31:27] = gpio_o[31:27];
  assign gpio_i[26:16] = gpio_bd_i;
  assign gpio_i[15: 0] = gpio_o[15:0];

  assign gpio_bd_o = gpio_o[15:0];

  system_bd i_system_bd (
    .ad9371_gpio_export (ad9371_gpio),
    .rx_data_0_rx_serial_data (rx_data[0]),
    .rx_data_1_rx_serial_data (rx_data[1]),
    .rx_data_2_rx_serial_data (rx_data[2]),
    .rx_data_3_rx_serial_data (rx_data[3]),
    .rx_os_ref_clk_clk (ref_clk1),
    .rx_os_sync_export (rx_os_sync),
    .rx_os_sysref_export (sysref),
    .rx_ref_clk_clk (ref_clk1),
    .rx_sync_export (rx_sync),
    .rx_sysref_export (sysref),
    .sys_clk_clk (sys_clk),
    .sys_ddr3_cntrl_mem_mem_ck (ddr3_clk_p),
    .sys_ddr3_cntrl_mem_mem_ck_n (ddr3_clk_n),
    .sys_ddr3_cntrl_mem_mem_a (ddr3_a[11:0]),
    .sys_ddr3_cntrl_mem_mem_ba (ddr3_ba),
    .sys_ddr3_cntrl_mem_mem_cke (ddr3_cke),
    .sys_ddr3_cntrl_mem_mem_cs_n (ddr3_cs_n),
    .sys_ddr3_cntrl_mem_mem_odt (ddr3_odt),
    .sys_ddr3_cntrl_mem_mem_reset_n (ddr3_reset_n),
    .sys_ddr3_cntrl_mem_mem_we_n (ddr3_we_n),
    .sys_ddr3_cntrl_mem_mem_ras_n (ddr3_ras_n),
    .sys_ddr3_cntrl_mem_mem_cas_n (ddr3_cas_n),
    .sys_ddr3_cntrl_mem_mem_dqs (ddr3_dqs_p[7:0]),
    .sys_ddr3_cntrl_mem_mem_dqs_n (ddr3_dqs_n[7:0]),
    .sys_ddr3_cntrl_mem_mem_dq (ddr3_dq[63:0]),
    .sys_ddr3_cntrl_mem_mem_dm (ddr3_dm[7:0]),
    .sys_ddr3_cntrl_oct_oct_rzqin (ddr3_rzq),
    .sys_ddr3_cntrl_pll_ref_clk_clk (ddr3_ref_clk),
    .sys_ethernet_mdio_mdc (eth_mdc),
    .sys_ethernet_mdio_mdio_in (eth_mdio_i),
    .sys_ethernet_mdio_mdio_out (eth_mdio_o),
    .sys_ethernet_mdio_mdio_oen (eth_mdio_t),
    .sys_ethernet_ref_clk_clk (eth_ref_clk),
    .sys_ethernet_reset_reset (eth_reset),
    .sys_ethernet_sgmii_rxp_0 (eth_rxd),
    .sys_ethernet_sgmii_txp_0 (eth_txd),
    .sys_gpio_bd_in_port (gpio_i[31:0]),
    .sys_gpio_bd_out_port (gpio_o[31:0]),
    .sys_gpio_in_export (gpio_i[63:32]),
    .sys_gpio_out_export (gpio_o[63:32]),
    .sys_rst_reset_n (sys_resetn),
    .sys_spi_MISO (spi_miso),
    .sys_spi_MOSI (spi_mosi),
    .sys_spi_SCLK (spi_clk),
    .sys_spi_SS_n (spi_csn_s),
    .tx_data_0_tx_serial_data (tx_data[0]),
    .tx_data_1_tx_serial_data (tx_data[1]),
    .tx_data_2_tx_serial_data (tx_data[2]),
    .tx_data_3_tx_serial_data (tx_data[3]),
    .tx_fifo_bypass_bypass (dac_fifo_bypass),
    .tx_ref_clk_clk (ref_clk1),
    .tx_sync_export (tx_sync),
    .tx_sysref_export (sysref));

endmodule

// ***************************************************************************
// ***************************************************************************
