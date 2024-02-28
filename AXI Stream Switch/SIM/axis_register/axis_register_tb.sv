`include "tb_interface.sv"
`include "packet.sv"
`include "configuration.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "test.sv"

module axis_register_tb();


    localparam T_DATA_WIDTH = 17;
    localparam T_ID_WIDTH = 10;
    localparam T_USER_WIDTH = 19;


    bit                             clk;
    bit                             reset_n;


    stream_intf 
    #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) s_intf (clk, reset_n);

    stream_intf 
    #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) m_intf (clk, reset_n);


    test #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) test_n;

    axis_register #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) DUT (
        .clk            (clk),
        .reset_n        (reset_n),
    
        .s_id_i         (s_intf.id      ),
        .s_data_i       (s_intf.data    ),
        .s_user_i       (s_intf.user    ),
        .s_last_i       (s_intf.last    ),
        .s_valid_i      (s_intf.valid   ),
        .s_ready_o      (s_intf.ready   ),
    
        .m_id_o         (m_intf.id      ),
        .m_data_o       (m_intf.data    ),
        .m_user_o       (m_intf.user    ),
        .m_last_o       (m_intf.last    ),
        .m_valid_o      (m_intf.valid   ),
        .m_ready_i      (m_intf.ready   )
    );



    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end


    task gen_reset();
        reset_n <= 1'b0;
        repeat(10) @ (posedge clk);
        reset_n <= 1'b1;
    endtask

    initial begin
        test_n = new(
            s_intf,
            m_intf
        );

        fork
            test_n.run();
            gen_reset();
        join
    end


endmodule