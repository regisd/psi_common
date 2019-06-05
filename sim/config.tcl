##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Benoit Stef
##############################################################################

#Constants
set LibPath "../.."

#Import psi::sim library
namespace import psi::sim::*

#Set library
add_library psi_common

#suppress messages
compile_suppress 135,1236
run_suppress 8684,3479,3813,8009,3812

# Library
add_sources $LibPath {
	psi_common/hdl/psi_common_array_pkg.vhd \
	psi_common/hdl/psi_common_math_pkg.vhd \
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_tb/hdl/psi_tb_compare_pkg.vhd \
	psi_tb/hdl/psi_tb_activity_pkg.vhd \
	psi_tb/hdl/psi_tb_axi_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {	
	psi_common_logic_pkg.vhd \
	psi_common_pulse_cc.vhd \
	psi_common_simple_cc.vhd \
	psi_common_status_cc.vhd \
	psi_common_tdp_ram.vhd \
	psi_common_sdp_ram.vhd \
	psi_common_sync_fifo.vhd \
	psi_common_async_fifo.vhd \
	psi_common_tickgenerator.vhd \
	psi_common_strobe_generator.vhd \
	psi_common_strobe_divider.vhd \
	psi_common_delay.vhd \
	psi_common_wconv_n2xn.vhd \
	psi_common_wconv_xn2n.vhd \
	psi_common_sync_cc_n2xn.vhd \
	psi_common_sync_cc_xn2n.vhd \
	psi_common_pl_stage.vhd \
	psi_common_multi_pl_stage.vhd \
	psi_common_par_tdm.vhd \
	psi_common_tdm_par.vhd \
	psi_common_arb_priority.vhd \
	psi_common_arb_round_robin.vhd \
	psi_common_tdm_mux.vhd \
	psi_common_pulse_shaper.vhd \
	psi_common_clk_meas.vhd \
	psi_common_spi_master.vhd \
	psi_common_axi_master_simple.vhd \
	psi_common_axi_master_full.vhd \
} -tag src

# testbenches
add_sources "../testbench" {
	psi_common_simple_cc_tb/psi_common_simple_cc_tb.vhd \
	psi_common_status_cc_tb/psi_common_status_cc_tb.vhd \
	psi_common_sync_fifo_tb/psi_common_sync_fifo_tb.vhd \
	psi_common_async_fifo_tb/psi_common_async_fifo_tb.vhd \
	psi_common_logic_pkg_tb/psi_common_logic_pkg_tb.vhd \
	psi_common_tickgenerator_tb/psi_common_tickgenerator_tb.vhd \
	psi_common_strobe_generator_tb/psi_common_strobe_generator_tb.vhd \
	psi_common_strobe_divider_tb/psi_common_strobe_divider_tb.vhd \
	psi_common_delay_tb/psi_common_delay_tb.vhd \
	psi_common_wconv_n2xn_tb/psi_common_wconv_n2xn_tb.vhd \
	psi_common_wconv_xn2n_tb/psi_common_wconv_xn2n_tb.vhd \
	psi_common_sync_cc_n2xn_tb/psi_common_sync_cc_n2xn_tb.vhd \
	psi_common_sync_cc_xn2n_tb/psi_common_sync_cc_xn2n_tb.vhd \
	psi_common_pl_stage_tb/psi_common_pl_stage_tb.vhd \
	psi_common_multi_pl_stage_tb/psi_common_multi_pl_stage_tb.vhd \
	psi_common_par_tdm_tb/psi_common_par_tdm_tb.vhd \
	psi_common_tdm_par_tb/psi_common_tdm_par_tb.vhd \
	psi_common_arb_priority_tb/psi_common_arb_priority_tb.vhd \
	psi_common_arb_round_robin_tb/psi_common_arb_round_robin_tb.vhd \
	psi_common_tdm_mux_tb/psi_common_tdm_mux_tb.vhd \
	psi_common_pulse_shaper_tb/psi_common_pulse_shaper_tb.vhd \
	psi_common_clk_meas_tb/psi_common_clk_meas_tb.vhd \
	psi_common_spi_master_tb/psi_common_spi_master_tb.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_pkg.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_simple_tf.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_axi_hs.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_split.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_max_transact.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_special.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb_case_internals.vhd \
	psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_pkg.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_simple_tf.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_axi_hs.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_user_hs.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb_case_large.vhd \
   psi_common_axi_master_full_tb/psi_common_axi_master_full_tb.vhd \
} -tag tb
	
#TB Runs
create_tb_run "psi_common_simple_cc_tb"
tb_run_add_arguments \
	"-gClockRatioN_g=3 -gClockRatioD_g=1" \
	"-gClockRatioN_g=101 -gClockRatioD_g=100" \
	"-gClockRatioN_g=99 -gClockRatioD_g=100" \
	"-gClockRatioN_g=3 -gClockRatioD_g=10"
add_tb_run

create_tb_run "psi_common_status_cc_tb"
tb_run_add_arguments \
	"-gClockRatioN_g=3 -gClockRatioD_g=1" \
	"-gClockRatioN_g=101 -gClockRatioD_g=100" \
	"-gClockRatioN_g=99 -gClockRatioD_g=100" \
	"-gClockRatioN_g=3 -gClockRatioD_g=10"
add_tb_run

create_tb_run "psi_common_sync_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRdyRstState_g=1" \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRdyRstState_g=0" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=RBW" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=WBR" \	
add_tb_run

create_tb_run "psi_common_async_fifo_tb"
tb_run_add_arguments \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRamBehavior_g=RBW -gRdyRstState_g=1" \
	"-gAlmFullOn_g=true -gAlmEmptyOn_g=true -gDepth_g=32 -gRamBehavior_g=RBW -gRdyRstState_g=0" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=RBW" \
	"-gAlmFullOn_g=false -gAlmEmptyOn_g=false -gDepth_g=128 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_common_tickgenerator_tb"
tb_run_add_arguments \
	"-gg_CLK_IN_MHZ=125 -gg_TICK_WIDTH=3"
add_tb_run

create_tb_run "psi_common_logic_pkg_tb"
add_tb_run

create_tb_run "psi_common_strobe_generator_tb"
tb_run_add_arguments \
	"-gfreq_clock_g=256300000 -gfreq_strobe_g=1230000" \
	"-gfreq_clock_g=26300000 -gfreq_strobe_g=123000"
add_tb_run

create_tb_run "psi_common_strobe_divider_tb"
tb_run_add_arguments \
	"-gRatio_g=6" \
	"-gRatio_g=13" \
	"-gRatio_g=1" \
	"-gRatio_g=0"
add_tb_run

create_tb_run "psi_common_delay_tb"
tb_run_add_arguments \
	"-gResource_g=BRAM" \
	"-gResource_g=SRL" \
	"-gResource_g=AUTO" \
	"-gResource_g=BRAM -gDelay_g=3 -gRamBehavior_g=RBW" \
	"-gResource_g=BRAM -gDelay_g=3 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_common_wconv_n2xn_tb"
add_tb_run

create_tb_run "psi_common_wconv_xn2n_tb"
add_tb_run

create_tb_run "psi_common_sync_cc_n2xn_tb"
tb_run_add_arguments \
	"-gRatio_g=2" \
	"-gRatio_g=4"
add_tb_run

create_tb_run "psi_common_sync_cc_xn2n_tb"
tb_run_add_arguments \
	"-gRatio_g=2" \
	"-gRatio_g=4"
add_tb_run

create_tb_run "psi_common_pl_stage_tb"
tb_run_add_arguments \
	"-gHandleRdy_g=true" \
	"-gHandleRdy_g=false"
add_tb_run

create_tb_run "psi_common_multi_pl_stage_tb"
tb_run_add_arguments \
	"-gHandleRdy_g=true" \
	"-gHandleRdy_g=false"
add_tb_run

create_tb_run "psi_common_par_tdm_tb"
add_tb_run

create_tb_run "psi_common_tdm_par_tb"
add_tb_run

create_tb_run "psi_common_arb_priority_tb"
add_tb_run

create_tb_run "psi_common_arb_round_robin_tb"
add_tb_run

create_tb_run "psi_common_tdm_mux_tb"
tb_run_add_arguments \
	"-gstr_del_g=0" \
	"-gstr_del_g=5"
add_tb_run

create_tb_run "psi_common_pulse_shaper_tb"
add_tb_run

create_tb_run "psi_common_clk_meas_tb"
add_tb_run

create_tb_run "psi_common_spi_master_tb"
tb_run_add_arguments \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=0 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=1 -gSpiCPHA_g=1 -gLsbFirst_g=false" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=0 -gLsbFirst_g=true" \
	"-gSpiCPOL_g=0 -gSpiCPHA_g=1 -gLsbFirst_g=true"
add_tb_run

create_tb_run "psi_common_axi_master_simple_tb"
tb_run_add_arguments \
	"-gImplWrite_g=true -gImplRead_g=true" \
	"-gImplWrite_g=true -gImplRead_g=false" \
	"-gImplWrite_g=false -gImplRead_g=true"
add_tb_run

create_tb_run "psi_common_axi_master_full_tb"
tb_run_add_arguments \
	"-gDataWidth_g=16 -gImplRead_g=true -gImplWrite_g=true" \
	"-gDataWidth_g=32 -gImplRead_g=true -gImplWrite_g=true" \
   "-gDataWidth_g=16 -gImplRead_g=false -gImplWrite_g=true" \
   "-gDataWidth_g=16 -gImplRead_g=true -gImplWrite_g=false"
add_tb_run


