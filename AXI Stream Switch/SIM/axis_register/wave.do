onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axis_register_tb/DUT/clk
add wave -noupdate /axis_register_tb/DUT/reset_n
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_id_i
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_data_i
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_user_i
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_last_i
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_valid_i
add wave -noupdate -expand -group sink /axis_register_tb/DUT/s_ready_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_id_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_data_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_user_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_last_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_valid_o
add wave -noupdate -expand -group source /axis_register_tb/DUT/m_ready_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {4683 ns}
