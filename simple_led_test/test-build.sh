#!/usr/bin/env bash

if [ -z "$F4PGA_INSTALL_DIR" ]; then
    echo "F4PGA_INSTALL_DIR is not set"
    exit 1
fi

mkdir build-test
cd build-test
src=../top.v
pcf=../quickfeather.pcf
f4pga_install=$F4PGA_INSTALL_DIR/eos-s3/share/f4pga
f4pga_tcl=$HOME/.conda/envs/eos-s3/lib/python3.7/site-packages/f4pga/wrappers/tcl
package=PD64

env TECHMAP_PATH=$f4pga_install/techmaps/pp3 \
    DEVICE_CELLS_SIM=$f4pga_install/arch/ql-eos-s3_wlcsp/cells/ram_sim.v \
    DEVICE_CELLS_MAP=$f4pga_install/arch/ql-eos-s3_wlcsp/cells/ram_map.v \
    OUT_JSON=top_synth.json \
    SYNTH_JSON=top.json \
    OUT_EBLIF=top.eblif \
    OUT_SYNTH_V=top_synth.v \
    OUT_FASM_EXTRA=top_fasm_extra.fasm \
    PART_JSON= \
    INPUT_XDC_FILES= \
    OUT_SDC=top_synth.sdc \
    USE_ROI=FALSE \
    PCF_FILE=$pcf \
    PINMAP_FILE=$f4pga_install/arch/ql-eos-s3_wlcsp/pinmap_$package.csv \
    PYTHON3=$(which python3) \
    yosys -r top -p "tcl $f4pga_tcl/eos-s3.f4pga.tcl" -l top_synth.json.log \
    $src >/dev/null 2>&1
touch top_fasm_extra.fasm
touch top_synth.sdc

python3 -m f4pga.utils.quicklogic.pp3.eos-s3.iomux_config \
    --eblif top.eblif \
    --pcf $pcf \
    --map $f4pga_install/arch/ql-eos-s3_wlcsp/pinmap_$package.csv \
    --output-format openocd \
    > top_iomux.openocd

vpr $f4pga_install/arch/ql-eos-s3_wlcsp/arch.timing.xml top.eblif \
    --device ql-eos-s3 \
    --read_rr_graph $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.rr_graph.real.bin \
    --max_router_iterations 500 \
    --routing_failure_predictor off \
    --router_high_fanout_threshold -1 \
    --constant_net_method route \
    --route_chan_width 100 \
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold PB-LOGIC:18 \
    --suppress_warnings noisy_warnings.log,sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment \
    --read_router_lookahead $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.lookahead.bin \
    --read_placement_delay_lookup $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.place_delay.bin \
    --pack >/dev/null 2>&1

python3 -m f4pga.utils.quicklogic.pp3.create_ioplace \
    --map $f4pga_install/arch/ql-eos-s3_wlcsp/pinmap_$package.csv \
    --blif top.eblif \
    --pcf $pcf \
    --net top.net \
    --out top_io.place

python3 -m f4pga.utils.quicklogic.pp3.create_place_constraints \
    --map $f4pga_install/arch/ql-eos-s3_wlcsp/clkmap_$package.csv \
    --blif top.eblif \
    --i top_io.place \
    --o top_constraints.place

vpr $f4pga_install/arch/ql-eos-s3_wlcsp/arch.timing.xml top.eblif \
    --device ql-eos-s3 \
    --read_rr_graph $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.rr_graph.real.bin \
    --max_router_iterations 500 \
    --routing_failure_predictor off \
    --router_high_fanout_threshold -1 \
    --constant_net_method route \
    --route_chan_width 100 \
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold PB-LOGIC:18 \
    --suppress_warnings noisy_warnings.log,sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment \
    --read_router_lookahead $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.lookahead.bin \
    --read_placement_delay_lookup $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.place_delay.bin \
    --fix_clusters top_constraints.place \
    --place > /dev/null 2>&1

vpr $f4pga_install/arch/ql-eos-s3_wlcsp/arch.timing.xml top.eblif \
    --device ql-eos-s3 \
    --read_rr_graph $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.rr_graph.real.bin \
    --max_router_iterations 500 \
    --routing_failure_predictor off \
    --router_high_fanout_threshold -1 \
    --constant_net_method route \
    --route_chan_width 100 \
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold PB-LOGIC:18 \
    --suppress_warnings noisy_warnings.log,sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment \
    --read_router_lookahead $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.lookahead.bin \
    --read_placement_delay_lookup $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.place_delay.bin \
    --route >/dev/null 2>&1

genfasm  $f4pga_install/arch/ql-eos-s3_wlcsp/arch.timing.xml top.eblif \
    --device ql-eos-s3 \
    --read_rr_graph $f4pga_install/arch/ql-eos-s3_wlcsp/rr_graph_ql-eos-s3_wlcsp.rr_graph.real.bin \
    --max_router_iterations 500 \
    --routing_failure_predictor off \
    --router_high_fanout_threshold -1 \
    --constant_net_method route \
    --route_chan_width 100 \
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold PB-LOGIC:18 \
    --suppress_warnings noisy_warnings.log,sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment \
    >/dev/null 2>&1

cmake -E copy vpr_stdout.log genhlc.log
cmake -E copy top.fasm top.genfasm.fasm
cat top.fasm top_fasm_extra.fasm > top.concat.fasm
cmake -E rename top.concat.fasm top.fasm

cat top.fasm > top.merged.fasm
qlfasm --no-default-bitstream --dev-type ql-eos-s3 top.merged.fasm top.bit
python3 -m quicklogic_fasm.bitstream_to_openocd top.bit top.openocd
