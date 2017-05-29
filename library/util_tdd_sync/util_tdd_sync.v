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
//
// Simple pulse generator for TDD control
// The module has two modes. In function of the state of sync_mode,
// the syncronization signal (sync_out) can get its value from an external
// source or from its internal generator.
//

`timescale 1ns/1ps

module util_tdd_sync #(

  parameter     TDD_SYNC_PERIOD = 100000000) (
  input                   clk,
  input                   rstn,

  input                   sync_mode,

  input                   sync_in,
  output  reg             sync_out);


  reg           sync_mode_d1 = 1'b0;
  reg           sync_mode_d2 = 1'b0;

  wire          sync_internal;
  wire          sync_external;

  // pulse generator

  util_pulse_gen #(
    .PULSE_PERIOD(TDD_SYNC_PERIOD)
  )
    i_tdd_sync (
    .clk (clk),
    .rstn (rstn),
    .pulse_period (31'd0),
    .pulse_period_en (1'd0),
    .pulse (sync_internal)
  );

  // synchronization logic

  always @(posedge clk) begin
    if(rstn == 1'b0) begin
      sync_mode_d1 <= 1'b0;
      sync_mode_d2 <= 1'b0;
    end else begin
      sync_mode_d1 <= sync_mode;
      sync_mode_d2 <= sync_mode_d1;
    end
  end

  // output logic

  assign sync_external = sync_in;
  always @(posedge clk) begin
    if(rstn == 1'b0) begin
      sync_out <= 1'b0;
    end else begin
      sync_out <= (sync_mode_d2 == 1'b0) ? sync_internal : sync_external;
    end
  end

endmodule

