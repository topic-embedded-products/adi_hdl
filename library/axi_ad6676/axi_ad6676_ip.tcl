# ip

source ../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create axi_ad6676
  "$ad_hdl_dir/library/xilinx/common/up_xfer_cntrl_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/ad_rst_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/up_xfer_status_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/up_clock_mon_constr.xdc" \
  "axi_ad6676.v" ]

adi_ip_properties axi_ad6676

adi_ip_add_core_dependencies { \
  analog.com:user:axi_adc_jesd204:1.0 \
}

set_property driver_value 0 [ipx::get_ports *rx_valid* -of_objects [ipx::current_core]]
set_property driver_value 0 [ipx::get_ports *dovf* -of_objects [ipx::current_core]]

ipx::save_core [ipx::current_core]

