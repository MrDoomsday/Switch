onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /irr_arbiter_tb/DUT/clk
add wave -noupdate /irr_arbiter_tb/DUT/reset_n
add wave -noupdate -expand -group request -radix binary /irr_arbiter_tb/DUT/req_i
add wave -noupdate -expand -group request /irr_arbiter_tb/DUT/req_ack_o
add wave -noupdate -expand -group grant -radix binary -childformat {{{/irr_arbiter_tb/DUT/gnt_o[7]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[6]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[5]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[4]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[3]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[2]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[1]} -radix binary} {{/irr_arbiter_tb/DUT/gnt_o[0]} -radix binary}} -subitemconfig {{/irr_arbiter_tb/DUT/gnt_o[7]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[6]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[5]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[4]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[3]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[2]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[1]} {-height 17 -radix binary} {/irr_arbiter_tb/DUT/gnt_o[0]} {-height 17 -radix binary}} /irr_arbiter_tb/DUT/gnt_o
add wave -noupdate -expand -group grant -radix unsigned -childformat {{{/irr_arbiter_tb/DUT/gnt_id_o[2]} -radix unsigned} {{/irr_arbiter_tb/DUT/gnt_id_o[1]} -radix unsigned} {{/irr_arbiter_tb/DUT/gnt_id_o[0]} -radix unsigned}} -subitemconfig {{/irr_arbiter_tb/DUT/gnt_id_o[2]} {-height 17 -radix unsigned} {/irr_arbiter_tb/DUT/gnt_id_o[1]} {-height 17 -radix unsigned} {/irr_arbiter_tb/DUT/gnt_id_o[0]} {-height 17 -radix unsigned}} /irr_arbiter_tb/DUT/gnt_id_o
add wave -noupdate -expand -group grant /irr_arbiter_tb/DUT/gnt_vld_o
add wave -noupdate -expand -group grant /irr_arbiter_tb/DUT/gnt_rdy_i
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/any_r
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/sub_mux_data_i0
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/sub_mux_data_i1
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/sub_mux_data_o
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/sub_mux_sel
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/mp_in
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/mp_out
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/mp_sel
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/point
add wave -noupdate -group internal_bus /irr_arbiter_tb/DUT/point_next
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {72210 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 245
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {71903 ns} {75500 ns}
