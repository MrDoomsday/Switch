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

module mux_unit_tb();

    localparam S_DATA_COUNT = 10;
    localparam M_DATA_COUNT = 10;
    localparam T_DATA_WIDTH = 64;
    localparam T_ID_WIDTH = $clog2(S_DATA_COUNT);
    localparam T_DEST_WIDTH = $clog2(M_DATA_COUNT);
    localparam NUM_CHANNEL = 0;



    bit                             clk;
    bit                             reset_n;


    logic   [S_DATA_COUNT-1:0][T_DATA_WIDTH-1:0]  s_data_i;
    logic   [S_DATA_COUNT-1:0][T_DEST_WIDTH-1:0]  s_dest_i;
    logic   [S_DATA_COUNT-1:0]                    s_last_i;
    logic   [S_DATA_COUNT-1:0]                    s_valid_i;
    logic   [S_DATA_COUNT-1:0]                    s_ready_o;

    genvar i;


    interface_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) s_intf [S_DATA_COUNT-1:0] (clk, reset_n);

    interface_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH)
    ) m_intf (clk, reset_n);


    test #(
        .S_DATA_COUNT   (S_DATA_COUNT),
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) test_n;


    generate 
        for(i = 0; i < S_DATA_COUNT; i++) begin
            assign s_data_i[i]      = s_intf[i].data;
            assign s_dest_i[i]      = s_intf[i].dest;
            assign s_last_i[i]      = s_intf[i].last;
            assign s_valid_i[i]     = s_intf[i].valid;
            assign s_intf[i].ready  = s_ready_o[i];
        end
    endgenerate


    mux_unit #(
        .S_DATA_COUNT   (S_DATA_COUNT   ),
        .T_DATA_WIDTH   (T_DATA_WIDTH   ),
        .M_DATA_COUNT   (M_DATA_COUNT   ),
        .NUM_CHANNEL    (NUM_CHANNEL    )
    ) DUT (
        .clk            (clk),
        .reset_n        (reset_n),
    
        .s_dest_i       (s_dest_i       ),
        .s_data_i       (s_data_i       ),
        .s_last_i       (s_last_i       ),
        .s_valid_i      (s_valid_i      ),
        .s_ready_o      (s_ready_o      ),
    
        .m_id_o         (m_intf.id      ),
        .m_data_o       (m_intf.data    ),
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