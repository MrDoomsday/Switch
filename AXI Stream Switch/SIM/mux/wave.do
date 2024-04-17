onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mux_unit_tb/DUT/clk
add wave -noupdate /mux_unit_tb/DUT/reset_n
add wave -noupdate /mux_unit_tb/DUT/st_chk_vld
add wave -noupdate /mux_unit_tb/DUT/st_pipe
add wave -noupdate /mux_unit_tb/DUT/pkt_process
add wave -noupdate /mux_unit_tb/DUT/req_next
add wave -noupdate /mux_unit_tb/DUT/req
add wave -noupdate /mux_unit_tb/DUT/req_ack
add wave -noupdate /mux_unit_tb/DUT/gnt
add wave -noupdate /mux_unit_tb/DUT/gnt_id
add wave -noupdate /mux_unit_tb/DUT/gnt_vld
add wave -noupdate /mux_unit_tb/DUT/gnt_rdy
add wave -noupdate /mux_unit_tb/DUT/state
add wave -noupdate /mux_unit_tb/DUT/active_channel
add wave -noupdate /mux_unit_tb/DUT/ready_master
add wave -noupdate {/mux_unit_tb/s_intf[0]/clk}
add wave -noupdate {/mux_unit_tb/s_intf[0]/reset_n}
add wave -noupdate -expand -group ch0 {/mux_unit_tb/s_intf[0]/dest}
add wave -noupdate -expand -group ch0 {/mux_unit_tb/s_intf[0]/data}
add wave -noupdate -expand -group ch0 {/mux_unit_tb/s_intf[0]/last}
add wave -noupdate -expand -group ch0 {/mux_unit_tb/s_intf[0]/valid}
add wave -noupdate -expand -group ch0 {/mux_unit_tb/s_intf[0]/ready}
add wave -noupdate -expand -group ch1 {/mux_unit_tb/s_intf[1]/dest}
add wave -noupdate -expand -group ch1 {/mux_unit_tb/s_intf[1]/data}
add wave -noupdate -expand -group ch1 {/mux_unit_tb/s_intf[1]/last}
add wave -noupdate -expand -group ch1 {/mux_unit_tb/s_intf[1]/valid}
add wave -noupdate -expand -group ch1 {/mux_unit_tb/s_intf[1]/ready}
add wave -noupdate -expand -group ch2 {/mux_unit_tb/s_intf[2]/dest}
add wave -noupdate -expand -group ch2 {/mux_unit_tb/s_intf[2]/data}
add wave -noupdate -expand -group ch2 {/mux_unit_tb/s_intf[2]/last}
add wave -noupdate -expand -group ch2 {/mux_unit_tb/s_intf[2]/valid}
add wave -noupdate -expand -group ch2 {/mux_unit_tb/s_intf[2]/ready}
add wave -noupdate -expand -group ch3 {/mux_unit_tb/s_intf[3]/dest}
add wave -noupdate -expand -group ch3 {/mux_unit_tb/s_intf[3]/data}
add wave -noupdate -expand -group ch3 {/mux_unit_tb/s_intf[3]/last}
add wave -noupdate -expand -group ch3 {/mux_unit_tb/s_intf[3]/valid}
add wave -noupdate -expand -group ch3 {/mux_unit_tb/s_intf[3]/ready}
add wave -noupdate -expand -group out /mux_unit_tb/m_intf/id
add wave -noupdate -expand -group out /mux_unit_tb/m_intf/data
add wave -noupdate -expand -group out /mux_unit_tb/m_intf/last
add wave -noupdate -expand -group out /mux_unit_tb/m_intf/valid
add wave -noupdate -expand -group out /mux_unit_tb/m_intf/ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {37550 ns} 1} {{Cursor 3} {37571 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 128
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
WaveRestoreZoom {37498 ns} {37692 ns}
