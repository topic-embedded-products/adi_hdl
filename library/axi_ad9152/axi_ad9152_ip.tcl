# ip

source ../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create axi_ad9152
adi_ip_files axi_ad9152 [list \
  "$ad_hdl_dir/library/xilinx/common/up_xfer_cntrl_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/ad_rst_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/up_xfer_status_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/up_clock_mon_constr.xdc" \
  "axi_ad9152.v" ]

adi_ip_properties axi_ad9152

adi_ip_add_core_dependencies { \
  analog.com:user:axi_dac_jesd204:1.0 \
}

set_property driver_value 0 [ipx::get_ports *dunf* -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports *tx_ready* -of_objects [ipx::current_core]]

ipx::save_core [ipx::current_core]

