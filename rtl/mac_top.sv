/* 
 * mac_top.sv
 * Francesco Conti <fconti@iis.ee.ethz.ch>
 *
 * Copyright (C) 2018 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

import mac_package::*;
import hwpe_ctrl_package::*;

module mac_top
#(
  parameter int unsigned N_CORES = 2,
  parameter int unsigned MP  = 4,
  parameter int unsigned ID  = 10
)
(
  // global signals
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  input  logic                                  test_mode_i,
  // events
  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
  // tcdm master ports
  hwpe_stream_intf_tcdm.master                  tcdm[MP-1:0],
  // periph slave port
  hwpe_ctrl_intf_periph.slave                   periph
);

  logic a_fifo_ready, b_fifo_ready, c_fifo_ready;

  hwpe_stream_intf_tcdm tcdm_prefifo [3:0] (
    .clk ( clk_i )
  );

  ctrl_streamer_t  streamer_ctrl;
  flags_streamer_t streamer_flags;
  ctrl_engine_t    engine_ctrl;
  flags_engine_t   engine_flags;

  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) a (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) b (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) c (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) d (
    .clk ( clk_i )
  );

  mac_engine i_engine (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .a_i              ( a.sink         ),
    .b_i              ( b.sink         ),
    .c_i              ( c.sink         ),
    .d_o              ( d.source       ),
    .ctrl_i           ( engine_ctrl    ),
    .flags_o          ( engine_flags   )
  );

  mac_streamer #(
    .MP ( MP )
  ) i_streamer (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .enable_i         ( enable         ),
    .clear_i          ( clear          ),
    .a_o              ( a.source       ),
    .b_o              ( b.source       ),
    .c_o              ( c.source       ),
    .d_i              ( d.sink         ),
    .tcdm             ( tcdm_prefifo   ),
    .a_fifo_ready     ( a_fifo_ready   ),
    .b_fifo_ready     ( b_fifo_ready   ),
    .c_fifo_ready     ( c_fifo_ready   ),
    .ctrl_i           ( streamer_ctrl  ),
    .flags_o          ( streamer_flags )
  );

  hwpe_stream_tcdm_fifo_load #(
    .FIFO_DEPTH ( 8 )
  ) i_a_tcdm_fifo (
    .clk_i       ( clk_i           ),
    .rst_ni      ( rst_ni          ),
    .clear_i     ( clear_i         ),
    .flags_o     (                 ),
    .ready_i     ( a_fifo_ready    ),
    .tcdm_slave  ( tcdm_prefifo[0] ),
    .tcdm_master ( tcdm[0]         )
  );

  hwpe_stream_tcdm_fifo_load #(
    .FIFO_DEPTH ( 8 )
  ) i_b_tcdm_fifo (
    .clk_i       ( clk_i           ),
    .rst_ni      ( rst_ni          ),
    .clear_i     ( clear_i         ),
    .flags_o     (                 ),
    .ready_i     ( b_fifo_ready    ),
    .tcdm_slave  ( tcdm_prefifo[1] ),
    .tcdm_master ( tcdm[1]         )
  );

  hwpe_stream_tcdm_fifo_load #(
    .FIFO_DEPTH ( 8 )
  ) i_c_tcdm_fifo (
    .clk_i       ( clk_i           ),
    .rst_ni      ( rst_ni          ),
    .clear_i     ( clear_i         ),
    .flags_o     (                 ),
    .ready_i     ( c_fifo_ready    ),
    .tcdm_slave  ( tcdm_prefifo[2] ),
    .tcdm_master ( tcdm[2]         )
  );

  hwpe_stream_tcdm_fifo_store #(
    .FIFO_DEPTH ( 8 )
  ) i_d_tcdm_fifo (
    .clk_i       ( clk_i           ),
    .rst_ni      ( rst_ni          ),
    .clear_i     ( clear_i         ),
    .flags_o     (                 ),
    .tcdm_slave  ( tcdm_prefifo[3] ),
    .tcdm_master ( tcdm[3]         )
  );

  mac_ctrl #(
    .N_CORES   ( 2  ),
    .N_CONTEXT ( 2  ),
    .N_IO_REGS ( 16 ),
    .ID ( ID )
  ) i_ctrl (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .evt_o            ( evt_o          ),
    .clear_o          ( clear          ),
    .ctrl_streamer_o  ( streamer_ctrl  ),
    .flags_streamer_i ( streamer_flags ),
    .ctrl_engine_o    ( engine_ctrl    ),
    .flags_engine_i   ( engine_flags   ),
    .periph           ( periph         )
  );

  assign enable = 1'b1;

endmodule // mac_top
